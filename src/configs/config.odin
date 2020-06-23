package configs

import "core:os"
import "core:mem"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:runtime"
import "core:reflect"

import "shared:wb"
import "shared:wb/logging"
import "shared:wb/math"
import "shared:wb/external/imgui"
import wb_reflect "shared:wb/reflection"
import platform "shared:wb/platform"
import wbml "shared:wb/wbml"

import "../shared"

CONFIG_PATH :: "resources/data/";

editor_config : Editor_Save;
key_config    : Key_Config;

meta_config : Meta_Config;
config_sections: map[string]Config_Section;
config_load_listeners: [dynamic]proc();

has_loaded := false;

init_config :: proc() {
    init_config_file(&meta_config, "meta", default_meta_config);
    init_config_file(&editor_config, "editor", default_editor_config);
    init_config_file(&key_config, "key_config", default_key_config);

    for sn in meta_config.sections {
        section_name := cast(string)sn;
        bytes, ok := os.read_entire_file(fmt.tprint(CONFIG_PATH, section_name, ".wbml"));
        if ok {
            section: Config_Section;
            wbml.deserialize(bytes, &section);
            config_sections[section_name] = section;
        } else {
            config_sections[section_name] = { section_name, {}, {} };
        }
    }

    has_loaded = true;
    config_save(); // apply any default configs that are not loaded
}

config_save :: proc() {
    save_config_file(&editor_config, "editor");
    save_config_file(&key_config, "key_config");

    save_config_file(&meta_config, "meta");
    for id, section in &config_sections {
        save_config_file(&section, id);
    }
}

// api
get_all_config_values :: proc(section_id: string, $T: typeid) -> []T {
    section := config_sections[section_id];
    all_vals := make([]T, len(section.rows));
    for r, i in section.rows {
        _get_config_value(&config_sections[section_id], r.key, T, &all_vals[i]);
    }

    return all_vals;
}

get_config_value :: proc(section_id, key: string, to_fill: ^$T) {
    _get_config_value(&config_sections[section_id], key, typeid_of(T), to_fill);
}

init_config_file :: proc(target: ^$T, file_name: string, default_initializer: proc() -> T) {
    bytes, ok := os.read_entire_file(fmt.tprint(CONFIG_PATH, file_name, ".wbml"));
    target^ = default_initializer();
    if ok {
        wbml.deserialize(bytes, target);
    }
}

save_config_file :: proc(target: ^$T, file_name: string) {
    bytes := wbml.serialize(target);
    defer delete(bytes);
    os.write_entire_file(fmt.tprint(CONFIG_PATH, file_name, ".wbml"), transmute([]u8)bytes);
}

add_config_load_listener :: proc(func: proc()) {
    append(&config_load_listeners, func);
    if has_loaded {
        func();
    }
}

Config_Section :: struct {
    name: string,
    column_names: [dynamic]string,
    rows: [dynamic]Row,
}

Row :: struct {
    key: string,
    columns: [dynamic]Entry
}

Entry :: struct {
    raw_data: string,
    entry_type: Entry_Type,
    sub_table: Config_Section,
}

Entry_Type :: enum { Raw, Sub_Table, }

_get_config_value :: proc(_section: ^Config_Section, _key: string, tid: typeid, to_fill: rawptr, column_name := "") {
    ti := type_info_of(tid);

    section := _section;
    key := _key;

    row: Row;
    for r in &section.rows {
        if r.key == key { row = r; break; }
    }
    
    if len(row.columns) <= 0 do return;

    column_idx := 0;
    if column_name != "" {
        for cn, i in section.column_names {
            if cn == column_name do column_idx = i;
        }
    }
    column_val := &row.columns[column_idx];

    // note(Jake): no asserts in here because we want to allow empty values
    #partial switch kind in &ti.variant {
        case runtime.Type_Info_Struct: {
            for field, i in kind.names {
                ft := kind.types[i];
                fp := rawptr(uintptr(int(uintptr(to_fill)) + int(kind.offsets[i])));

                if _, is_struct := ft.variant.(runtime.Type_Info_Struct); is_struct && column_name != "" {
                    section = &column_val.sub_table;
                    key = section.rows[0].key;
                }

                _get_config_value(section, key, ft.id, fp, field);
            }
        }
        case runtime.Type_Info_Named: {
            if _, is_struct := kind.base.variant.(runtime.Type_Info_Struct); is_struct && column_name != "" {
                    section = &column_val.sub_table;
                    if len(section.rows) > 0 do key = section.rows[0].key;
                }
            _get_config_value(section, key, kind.base.id, to_fill);
        }
        case runtime.Type_Info_Integer: {
            if kind.signed {
                if v, ok := strconv.parse_int(column_val.raw_data, 10); ok {
                    mem.copy(to_fill, &v, ti.size);
                }
            } else {
                if v, ok := strconv.parse_uint(column_val.raw_data, 10); ok {
                    mem.copy(to_fill, &v, ti.size);
                }
            }
        }
        case runtime.Type_Info_Float: {
            if ti.size == 8 {
                if v, ok := strconv.parse_f64(column_val.raw_data); ok {
                    mem.copy(to_fill, &v, ti.size);
                }
            } else {
                if v, ok := strconv.parse_f32(column_val.raw_data); ok {
                    mem.copy(to_fill, &v, ti.size);
                }
            }
        }
        case runtime.Type_Info_String: {
            mem.copy(to_fill, &column_val.raw_data, size_of(string));
        }
        case runtime.Type_Info_Boolean: {
            if v, ok := strconv.parse_bool(column_val.raw_data); ok {
                mem.copy(to_fill, &v, ti.size);
            }
        }
        case runtime.Type_Info_Enum: {
            for value_name, i in kind.names {
                if value_name != column_val.raw_data do continue;
                mem.copy(to_fill, &kind.values[i], ti.size);
            }
        }
        case runtime.Type_Info_Union: {
            for v, i in &kind.variants {
                v_name := fmt.tprint(v);
                if len(column_val.sub_table.rows) <= 0 do continue;
                if v_name == column_val.sub_table.rows[0].key {
                    wb_reflect.set_union_type_info(any{to_fill, tid}, v);
                    _get_config_value(&column_val.sub_table, v_name, v.id, to_fill);
                    break;
                }
            }
        }
        case runtime.Type_Info_Quaternion: { // TODO(jake): support this and vectors

        }
        case runtime.Type_Info_Array: {

        }
        case runtime.Type_Info_Enumerated_Array: {

        }
        case runtime.Type_Info_Dynamic_Array: {

        }
        case runtime.Type_Info_Slice: {

        }
        case runtime.Type_Info_Map: {

        }
        case: {
            panic(fmt.tprint("(", section.name, "-", key, "): Unsupported type: ", ti.variant));
        }
    }
}

draw_config_window :: proc(userdata: rawptr) {
    if imgui.begin("Configs") {

        // imgui.label_text("Add Section:"); imgui.same_line();
        if imgui.button("+") { // add config "section"
            imgui.open_popup("add_section");
        }

        if imgui.begin_popup("add_section") {
            text_edit_buffer: [256]u8;
            imgui.set_keyboard_focus_here();
            if imgui.input_text("Section Name", text_edit_buffer[:], .EnterReturnsTrue) {
                result := text_edit_buffer[:];
                for b, i in text_edit_buffer {
                    if b == '\x00' {
                        result = text_edit_buffer[:i];
                        break;
                    }
                }
                if cast(string)result != "" {
                    append(&meta_config.sections, strings.clone_to_cstring(cast(string)result));
                }
                imgui.close_current_popup();
            }
            imgui.end_popup();
        }

        imgui.same_line();
        if imgui.button("R") {
            for on_load in config_load_listeners {
                on_load();
            }
        }

        imgui.columns(2, "main_columns", false);
        imgui.set_column_width(0, imgui.get_window_content_region_width() * 0.2);
        
        @static selected_index := 0;
        imgui.begin_child("section_slection", {imgui.get_window_content_region_width() * 0.8, -1}, true, .HorizontalScrollbar);
        for sec, i in meta_config.sections {
            if imgui.selectable(cast(string)sec, selected_index == i) {
                selected_index = i;
            }
        }
        imgui.end_child();
        
        imgui.next_column();

        // selected section content
        selected_section := &config_sections[cast(string)meta_config.sections[selected_index]];
        draw_config_section(selected_section);

    } imgui.end();
}

draw_config_section :: proc(section: ^Config_Section, is_modal := false) {
    row_count := len(section.rows);
    if row_count < 1 {
        row_count = 1;
        add_row(section, 0);
        add_column(section, is_modal ? 1 : 5);

    }
    column_count := len(section.column_names);

    if !is_modal {
        child_size := imgui.get_window_content_region_width() * 0.8;
        column_size := child_size / 10;
        imgui.set_next_window_content_size({child_size + f32(column_count-10)*column_size , 0});
        imgui.begin_child("section_content", {child_size,0}, true, .HorizontalScrollbar);
    } else {
        imgui.begin_child("section_content");
    }

    child_size: imgui.Vec2;
    imgui.im_get_window_size(&child_size);

    column_remove_idx := -1;

    // add 1 for keys, 1 for ghost columns
    imgui.columns(i32(column_count + 2), fmt.tprint("section_columns_", column_count), true);
    // headers
    for column in 0..<column_count+2 {
        imgui.push_id(fmt.tprint("header-", column));
        if column == 0 do imgui.text("Key");
        else if column != column_count+1 {
            imgui.push_id(fmt.tprint(section.name, "-", column));
            section.column_names[column-1] = input_text("", section.column_names[column-1]);
            if imgui.begin_popup_context_item("column_title_context") {
                if imgui.button("Remove Column") {
                    column_remove_idx = column-1;
                    imgui.close_current_popup();
                }
                imgui.end_popup();
            }
            imgui.pop_id();
        }
        imgui.pop_id();
        imgui.next_column();
    }
    imgui.separator();

    if column_remove_idx >= 0 {
        for row in &section.rows {
            ordered_remove(&row.columns, column_remove_idx);
        }
        ordered_remove(&section.column_names, column_remove_idx);
    }

    should_add_column := false;

    remove_idx := -1;

    for row_idx in 0..<row_count {
        row := &section.rows[row_idx];
        imgui.push_id(fmt.tprint("row-", row_idx, "-", section.name));
        defer imgui.pop_id();
        for column in 0..<column_count+2 {
            imgui.push_id(fmt.tprint(row_idx,"-",column));
            if column == column_count+1 {
                if imgui.button("add column") {
                    should_add_column = true;
                }
            } else {
                if column == 0 {
                    row.key = input_text("", row.key);
                    if imgui.begin_popup_context_item("row_title_context") {
                        if imgui.button("Remove Row") {
                            remove_idx = row_idx;
                            imgui.close_current_popup();
                        }
                        imgui.end_popup();
                    }
                }
                else {
                    entry := &row.columns[column-1];
                    
                    if entry.entry_type == .Raw {
                        entry.raw_data = input_text("", entry.raw_data);
                    } else {
                        imgui.push_item_width(-1);
                        defer imgui.pop_item_width();

                        sub_table_id := fmt.tprint(section.column_names[column-1], "_subtable_", row_idx);
                        sub_table_name := section.column_names[column-1];

                        @static modal_states: map[string]bool;
                        if sub_table_id notin modal_states {
                            modal_states[sub_table_name] = false;
                        }

                        imgui.push_id(sub_table_id);
                        if imgui.button("...") {
                            imgui.open_popup(sub_table_name);
                            modal_states[sub_table_id] = true;
                        }

                        imgui.set_next_window_size({child_size.x*0.75, child_size.y*0.75});
                        if imgui.begin_popup_modal(sub_table_name, &modal_states[sub_table_id]) {
                            draw_config_section(&entry.sub_table, true);
                            imgui.end_popup();
                        }
                        imgui.pop_id();
                    }

                    if imgui.begin_popup_context_item("type-selection") {
                        if imgui.button("Raw") {
                            entry.entry_type = .Raw;
                            imgui.close_current_popup();
                        }
                        if imgui.button("Sub-Table") {
                            entry.entry_type = .Sub_Table;
                            imgui.close_current_popup();
                        }
                        imgui.end_popup();
                    }                    
                }
            }
            imgui.pop_id();
            imgui.next_column();
        }
    }

    if imgui.button("add row") {
        add_row(section, column_count);
    }
    if should_add_column {
        add_column(section);
    }

    if remove_idx >= 0 {
        ordered_remove(&section.rows, remove_idx);
    }

    imgui.end_child();
}

// Helper functions
// TODO(jake): custom allocator?
input_text :: proc(label, input: string) -> string {
    text_edit_buffer: [256]u8;
    fmt.bprint(text_edit_buffer[:], input);
    
    imgui.push_item_width(-1);
    defer imgui.pop_item_width();
    if imgui.input_text(label, text_edit_buffer[:]) {
        result := text_edit_buffer[:];
        for b, i in text_edit_buffer {
            if b == '\x00' {
                result = text_edit_buffer[:i];
                break;
            }
        }

        delete(input);
        return strings.clone(cast(string)result);
    }
    return input;    
}

add_row :: proc(section: ^Config_Section, column_count : int) {
    row := Row{};
    for _ in 0..column_count {
        append(&row.columns, Entry{});
    }
    append(&section.rows, row);
    // return &section.rows[len(section.rows)-1];
}

add_column :: proc(section: ^Config_Section, count := 1) {
    for _ in 0..<count {
        for row in &section.rows {
            append(&row.columns, Entry{});
        }
        append(&section.column_names, "");
    }
}


Meta_Config :: struct {
    sections: [dynamic]cstring,
}
default_meta_config :: proc() -> Meta_Config {
    return Meta_Config {
        { "Spells" }
    };
}

Editor_Save :: struct {
    camera_position: math.Vec3,
    camera_rotation: math.Quat,
}
default_editor_config :: proc() -> Editor_Save {
    return Editor_Save {
        math.Vec3{}, 
        math.Quat{},
    };
}

Game_Input :: platform.Input;
Key_Config :: struct {

    // Editor
    toggle_editor: Game_Input,

    camera_up:      Game_Input,
    camera_down:    Game_Input,
    camera_forward: Game_Input,
    camera_back:    Game_Input,
    camera_left:    Game_Input,
    camera_right:   Game_Input,
    camera_speed_boost: Game_Input,

    camera_free_move: Game_Input,
    camera_scroll: Game_Input,
    editor_select: Game_Input,

    // Game
    interact : Game_Input,
    select : Game_Input,

    spell_1 : Game_Input,
    spell_2 : Game_Input,
    spell_3 : Game_Input,
    spell_4 : Game_Input,
    spell_5 : Game_Input,
}
default_key_config :: proc() -> Key_Config {
    using platform.Input;

    return Key_Config{
        toggle_editor = F2,

        // Editor
        camera_up      = E,
        camera_down    = Q,
        camera_forward = W,
        camera_back    = S,
        camera_left    = A,
        camera_right   = D,
        camera_speed_boost = Shift,

        camera_scroll = Mouse_Middle,
        camera_free_move = Mouse_Right,
        editor_select = Mouse_Left,

        // Game
        interact = Mouse_Right,
        select = Mouse_Left,
        spell_1 = Q,
        spell_2 = W,
        spell_3 = E,
        spell_4 = R,
        spell_5 = T,
    };
}
input_to_nice_name :: proc(input: platform.Input) -> string {
    using platform.Input;

    #partial switch input {
        case Mouse_Left:          return "LMB";
        case Mouse_Right:          return "RMB";
        case Mouse_Middle:          return "MMB";
        case Space:                   return "Space";
        case Apostrophe:              return "Apostrophe";
        case Comma:                   return "Comma";
        case Minus:                   return "Minus";
        case Period:                  return "Period";
        case Forward_Slash:           return "Slash";
        case Semicolon:               return "Semicolon";
        case NR_0:                    return "0";
        case NR_1:                    return "1";
        case NR_2:                    return "2";
        case NR_3:                    return "3";
        case NR_4:                    return "4";
        case NR_5:                    return "5";
        case NR_6:                    return "6";
        case NR_7:                    return "7";
        case NR_8:                    return "8";
        case NR_9:                    return "9";
        case A:                       return "A";
        case B:                       return "B";
        case C:                       return "C";
        case D:                       return "D";
        case E:                       return "E";
        case F:                       return "F";
        case G:                       return "G";
        case H:                       return "H";
        case I:                       return "I";
        case J:                       return "J";
        case K:                       return "K";
        case L:                       return "L";
        case M:                       return "M";
        case N:                       return "N";
        case O:                       return "O";
        case P:                       return "P";
        case Q:                       return "Q";
        case R:                       return "R";
        case S:                       return "S";
        case T:                       return "T";
        case U:                       return "U";
        case V:                       return "V";
        case W:                       return "W";
        case X:                       return "X";
        case Y:                       return "Y";
        case Z:                       return "Z";
        case Escape:                  return "Escape";
        case Enter:                   return "Enter";
        case Tab:                     return "Tab";
        case Backspace:               return "Backspace";
        case Insert:                  return "Insert";
        case Delete:                  return "Delete";
        case Right:                   return "Right";
        case Left:                    return "Left";
        case Down:                    return "Down";
        case Up:                      return "Up";
        case Page_Up:                 return "Page Up";
        case Page_Down:               return "Page Down";
        case Home:                    return "Home";
        case End:                     return "End";
        case Caps_Lock:               return "Caps Lock";
        case Scroll_Lock:             return "Scroll Lock";
        case Num_Lock:                return "Num Lock";
        case Print_Screen:            return "Print Screen";
        case Pause:                   return "Pause";
        case F1:                      return "F1";
        case F2:                      return "F2";
        case F3:                      return "F3";
        case F4:                      return "F4";
        case F5:                      return "F5";
        case F6:                      return "F6";
        case F7:                      return "F7";
        case F8:                      return "F8";
        case F9:                      return "F9";
        case F10:                     return "F10";
        case F11:                     return "F11";
        case F12:                     return "F12";
    }

    assert(false, fmt.tprint(input));
    return "";
}

logln :: logging.logln;