package editor

import "shared:wb/logging"
import "core:fmt"
import "core:strings"
import "core:mem"
import "core:runtime"
import "core:math"
import "core:log"
import la "core:math/linalg"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/imgui"
import "shared:wb/reflection"
import "shared:wb/profiler"

import "../configs"
import "../entity"
import "../shared"
import "../util"

g_editor_camera: wb.Camera;

entity_id_color_buffer: wb.Texture;
entity_id_depth_buffer: wb.Texture;
entity_id_buffer_cpu_copy: wb.Texture;

hovered_entity_index: int;

gizmo_state: Gizmo_State;

init :: proc() {
    wb.track_asset_folder("resources/editor");

    wb.init_camera(&g_editor_camera);
    g_editor_camera.is_perspective = true;

    entity_id_color_buffer, entity_id_depth_buffer = wb.create_color_and_depth_buffers(wb.main_window.width_int, wb.main_window.height_int, .R32_INT);

    eid_texture_desc := entity_id_color_buffer.description;
    eid_texture_desc.render_target = false;
    eid_texture_desc.is_cpu_read_target = true;
    entity_id_buffer_cpu_copy = wb.create_texture(eid_texture_desc);

    game_texture_desc := wb.Texture_Description {
        type = .Texture2D,
        width = shared.WINDOW_SIZE_X,
        height = shared.WINDOW_SIZE_Y,
        format = .R8G8B8A8_UINT,
        render_target = true
    };
    g_game_view_texture = wb.create_texture(game_texture_desc);

    init_gizmo();

    wb.register_developer_program("Inspector", draw_inspector, .Window, nil);
    wb.register_developer_program("Hierarchy", draw_scene_hierarchy, .Window, nil);
    wb.register_developer_program("Resources", draw_resource_inspector, .Window, nil);
    wb.register_developer_program("Game View", draw_game_view, .Window, nil);
    wb.register_developer_program("Console",   draw_console, .Window, nil);

    for open_prog in configs.editor_config.open_editor_windows {
        for prog in &wb.developer_programs {
            if prog.name == open_prog {
                prog.is_open = true;
                break;
            }
        }
    }

    register_modal("Select Entity", draw_entity_select_modal, nil);
}

update :: proc(dt: f32) {
    profiler.TIMED_SECTION("editor update");
    gizmo_new_frame();
    
    // Get entity mouse is hovering
    {
        pixels := wb.get_texture_pixels(&entity_id_buffer_cpu_copy);
        defer wb.return_texture_pixels(&entity_id_buffer_cpu_copy, pixels);

        hovered_entity_index = -1;
        pixels_int := mem.slice_data_cast([]i32, pixels);
        idx := cast(int)g_game_view_mouse_pos.x + cast(int)(shared.WINDOW_SIZE_Y - g_game_view_mouse_pos.y) * entity_id_buffer_cpu_copy.width;
        if idx >= 0 && idx < len(pixels_int) {
            hovered_entity_index = cast(int)pixels_int[idx];
        }
    }

    if !g_can_move_game_view && wb.get_global_input(.Mouse_Right) {
        g_clicked_outside_scene = true;
    }

    if wb.get_global_input_up(.Mouse_Right) {
        g_clicked_outside_scene = false;
    }

    if g_can_move_game_view && !g_clicked_outside_scene && wb.get_global_input(.Mouse_Right) {
        wb.do_camera_movement(&g_editor_camera.position, &g_editor_camera.orientation, dt, 5, 10, 1, true);
    }

    selected_count := len(selected_entities);
    if selected_count == 1 {
        selected_entity := entity.get_entity(selected_entities[0]);

        @static move_action: Memory_Action;
        @static rotate_action: Memory_Action;
        @static scale_action: Memory_Action;
        if !gizmo_state.is_manipulating {
            move_action   = create_memory_action(&selected_entity.position);
            rotate_action = create_memory_action(&selected_entity.rotation);
            scale_action  = create_memory_action(&selected_entity.scale);
        }

        gizmo_result := gizmo_manipulate(&selected_entity.position, &selected_entity.scale, &selected_entity.rotation, &g_editor_camera, &gizmo_state);
        if gizmo_result != nil {
            switch k in gizmo_result {
                case Gizmo_Move:   commit_memory_action(move_action);
                case Gizmo_Rotate: commit_memory_action(rotate_action);   
                case Gizmo_Scale:  commit_memory_action(scale_action);
            }

            entity.dirty_scene(); // TODO dirty touched scene
        }
    } 
    else if selected_count > 1 {
        // TODO put the gizmo in the center, and affect all selected things
    }

    if wb.get_global_input_down(.Mouse_Left, true) && g_can_move_game_view && !gizmo_state.is_manipulating {
        select_entity(hovered_entity_index, !wb.get_input(.Control));
    }

    // Control commands
    if wb.get_input(.Control) {
        if wb.get_input_down(.Z, true) {
            if wb.get_input(.Shift) do redo();
            else do undo();
        }

        if wb.get_input_down(.S, true) {
            entity.save_all();
            // if wb.get_input(.Shift) do entity.save_all();
            // else do entity.save_scene(); // TODO get last touched scene
        }
    }

    if imgui.is_mouse_double_clicked(.Left) && (g_hierarchy_window_hovered || g_game_view_window_hovered) {
        if len(selected_entities) > 0 {
            target := entity.get_entity(selected_entities[0]);
            assert(target != nil);
            dir := norm(target.position - g_editor_camera.position);
            g_editor_camera.position = target.position - dir * 5; // TODO actually frame the entity
        }
    }

    if wb.get_input_down(.Delete, true) {
        // TODO undo/redo
        for eid in selected_entities {
            entity.remove_from_scene(entity.get_entity(eid));
            entity.destroy_entity(eid);
        }
        entity.dirty_scene();
        clear(&selected_entities);
    }

    for modal in &modals {
        if modal.is_open && !imgui.is_popup_open(modal.name) do
            imgui.open_popup(modal.name);
        if !imgui.begin_popup_modal(modal.name, &modal.is_open) do return;
        defer imgui.end_popup();
        modal.procedure(&modal, modal.userdata);
    }
}

render :: proc(render_graph: ^wb.Render_Graph, ctxt: ^shared.Render_Graph_Context) {
    wb.add_render_graph_node(render_graph, "entity id texture", ctxt, 
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.read_resource(render_graph, "scene draw list");
            wb.has_side_effects(render_graph);
        },
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            render_context := cast(^shared.Render_Graph_Context)userdata;

            draw_commands := wb.get_resource(render_graph, "scene draw list", []Draw_Command);

            pass_desc: wb.Render_Pass;
            pass_desc.camera = render_context.target_camera;
            pass_desc.color_buffers[0] = &entity_id_color_buffer;
            pass_desc.depth_buffer     = &entity_id_depth_buffer;
            wb.BEGIN_RENDER_PASS(&pass_desc);

            for cmd in draw_commands {
                if cmd.entity == nil do continue;
                e := cast(^entity.Entity)cmd.entity;
                id_material := wb.g_materials["entity_id_mtl"]; 
                wb.set_material_property(id_material, "entity_id", cast(i32)e.id);
                wb.draw_model(cmd.model, cmd.position, cmd.scale, cmd.orientation, id_material);
            }

            wb.ensure_texture_size(&entity_id_buffer_cpu_copy, entity_id_color_buffer.width, entity_id_color_buffer.height);
            wb.copy_texture(&entity_id_buffer_cpu_copy, &entity_id_color_buffer);
        });

    wb.add_render_graph_node(render_graph, "gizmo", ctxt,
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.has_side_effects(render_graph);
        },
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            render_context := cast(^shared.Render_Graph_Context)userdata;

            gizmo_render(render_graph, render_context.editor_im_context);
        });

    wb.add_render_graph_node(render_graph, "scene view", ctxt,
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.has_side_effects(render_graph);
            wb.read_resource(render_graph, "game view color");
        },
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            game_view := wb.get_resource(render_graph, "game view color", wb.Texture);
            wb.ensure_texture_size(&g_game_view_texture, game_view.width, game_view.height);
            wb.copy_texture(&g_game_view_texture, game_view);
        });
}

shutdown :: proc() {
    clear(&configs.editor_config.open_editor_windows);
    for editr in wb.developer_programs {
        if !editr.is_open do continue;
        append(&configs.editor_config.open_editor_windows, editr.name);
    }
}



// Editor Windows

draw_inspector :: proc(userdata: rawptr, open: ^bool) {

    edited := false;

    // No multi selection for now
    if imgui.begin("Entity Inspector", open) && len(selected_entities) == 1 {
        selected_entity := entity.get_entity(selected_entities[0]);

        // Name
        // TODO I hate imgui input text
        bprint(selected_entity.name_buffer[:], selected_entity.name);
        selected_entity.name_buffer[len(selected_entity.name)] = 0;
        edited |= imgui.input_text("", selected_entity.name_buffer[:]);
        selected_entity.name = cast(string)cast(cstring)&selected_entity.name_buffer[0];

        // Enabled
        imgui.same_line();
        imgui.checkbox("Enabled", &selected_entity.active);

        // Tags
        // TODO I hate imgui input text
        bprint(selected_entity.tags_buffer[:], selected_entity.tags);
        selected_entity.tags_buffer[len(selected_entity.tags)] = 0;
        edited |= imgui.input_text("Tags:", selected_entity.tags_buffer[:]);
        selected_entity.tags = cast(string)cast(cstring)&selected_entity.tags_buffer[0];        

        // Transform info
        imgui.separator();
        imgui.text("Transform"); 
        {
            imgui.push_id("pos");
            defer imgui.pop_id();

            imgui.text("Position"); imgui.same_line();

            imgui.push_item_width(100);
            defer imgui.pop_item_width();
            
            edited |= imgui.input_float("x", &selected_entity.position.x); imgui.same_line();
            edited |= imgui.input_float("y", &selected_entity.position.y); imgui.same_line();
            edited |= imgui.input_float("z", &selected_entity.position.z);
        }

        {
            imgui.push_id("rot");
            defer imgui.pop_id();

            // x,y,z := la.pitch_yaw_roll_from_quaternion(selected_entity.rotation);
            // x = x * la.RAD_PER_DEG; y = y * la.RAD_PER_DEG; z = z * la.RAD_PER_DEG;
            // defer {
            //     x = x * la.DEG_PER_RAD; y = y * la.DEG_PER_RAD; z = z * la.DEG_PER_RAD;
            //     selected_entity.rotation = la.quaternion_from_pitch_yaw_roll(x, y, z);
            // }

            imgui.text("Rotation"); imgui.same_line();
            
            imgui.push_item_width(100); 
            defer imgui.pop_item_width();
            
            edited |= imgui.input_float("x", &selected_entity.rotation.x); imgui.same_line();
            edited |= imgui.input_float("y", &selected_entity.rotation.y); imgui.same_line();
            edited |= imgui.input_float("z", &selected_entity.rotation.y); imgui.same_line();
            edited |= imgui.input_float("w", &selected_entity.rotation.z);
        }

        {
            imgui.push_id("scale");
            defer imgui.pop_id();

            imgui.text("Scale"); imgui.same_line();
            
            imgui.push_item_width(100);
            defer imgui.pop_item_width();
            
            edited |= imgui.input_float("x", &selected_entity.scale.x); imgui.same_line();
            edited |= imgui.input_float("y", &selected_entity.scale.y); imgui.same_line();
            edited |= imgui.input_float("z", &selected_entity.scale.z);
        }

        auto_field_gen :: proc(name: string, ti: ^runtime.Type_Info, data: rawptr, tags: string, is_root := true) -> bool {
            if strings.contains(tags, "hidden") do return false;

            if !is_root do imgui.indent();
            imgui.push_id(name);
            defer imgui.pop_id();

            edited := false;

            #partial switch kind in ti.variant {
                case runtime.Type_Info_Integer: {
                    if kind.signed {
                        switch ti.size {
                            case 8: new_data := cast(i32)(cast(^i64)data)^; edited |= imgui.input_int(name, &new_data); (cast(^i64)data)^ = cast(i64)new_data;
                            case 4: new_data := cast(i32)(cast(^i32)data)^; edited |= imgui.input_int(name, &new_data); (cast(^i32)data)^ = cast(i32)new_data;
                            case 2: new_data := cast(i32)(cast(^i16)data)^; edited |= imgui.input_int(name, &new_data); (cast(^i16)data)^ = cast(i16)new_data;
                            case 1: new_data := cast(i32)(cast(^i8 )data)^; edited |= imgui.input_int(name, &new_data); (cast(^i8 )data)^ = cast(i8 )new_data;
                            case: assert(false, tprint(ti.size));
                        }
                    }
                    else {
                        switch ti.size {
                            case 8: new_data := cast(i32)(cast(^u64)data)^; edited |= imgui.input_int(name, &new_data); (cast(^u64)data)^ = cast(u64)new_data;
                            case 4: new_data := cast(i32)(cast(^u32)data)^; edited |= imgui.input_int(name, &new_data); (cast(^u32)data)^ = cast(u32)new_data;
                            case 2: new_data := cast(i32)(cast(^u16)data)^; edited |= imgui.input_int(name, &new_data); (cast(^u16)data)^ = cast(u16)new_data;
                            case 1: new_data := cast(i32)(cast(^u8 )data)^; edited |= imgui.input_int(name, &new_data); (cast(^u8 )data)^ = cast(u8 )new_data;
                            case: assert(false, tprint(ti.size));
                        }
                    }
                }
                case runtime.Type_Info_Float: {
                    switch ti.size {
                        case 8: {}
                        case 4: {
                            new_data := cast(f32)(cast(^f32)data)^;
                            imgui.push_item_width(100);
                            imgui.input_float(tprint(name, "##non_range"), &new_data);
                            imgui.pop_item_width();
                            (cast(^f32)data)^ = cast(f32)new_data;
                        }
                        case: assert(false, tprint(ti.size));
                    }
                }
                case runtime.Type_Info_Boolean: {
                    imgui.checkbox(name, cast(^bool)data);
                }
                case runtime.Type_Info_Enum: {
                     if len(kind.values) > 0 {
                        current_item_index : i32 = -1;
                        switch kind.base.id {
                            case u8:        for v, idx in kind.values { if (cast(^u8     )data)^ == cast(u8     )v { current_item_index = cast(i32)idx; break; } }
                            case u16:       for v, idx in kind.values { if (cast(^u16    )data)^ == cast(u16    )v { current_item_index = cast(i32)idx; break; } }
                            case u32:       for v, idx in kind.values { if (cast(^u32    )data)^ == cast(u32    )v { current_item_index = cast(i32)idx; break; } }
                            case u64:       for v, idx in kind.values { if (cast(^u64    )data)^ == cast(u64    )v { current_item_index = cast(i32)idx; break; } }
                            case uint:      for v, idx in kind.values { if (cast(^uint   )data)^ == cast(uint   )v { current_item_index = cast(i32)idx; break; } }
                            case i8:        for v, idx in kind.values { if (cast(^i8     )data)^ == cast(i8     )v { current_item_index = cast(i32)idx; break; } }
                            case i16:       for v, idx in kind.values { if (cast(^i16    )data)^ == cast(i16    )v { current_item_index = cast(i32)idx; break; } }
                            case i32:       for v, idx in kind.values { if (cast(^i32    )data)^ == cast(i32    )v { current_item_index = cast(i32)idx; break; } }
                            case i64:       for v, idx in kind.values { if (cast(^i64    )data)^ == cast(i64    )v { current_item_index = cast(i32)idx; break; } }
                            case int:       for v, idx in kind.values { if (cast(^int    )data)^ == cast(int    )v { current_item_index = cast(i32)idx; break; } }
                            case rune:      for v, idx in kind.values { if (cast(^rune   )data)^ == cast(rune   )v { current_item_index = cast(i32)idx; break; } }
                            case uintptr:   for v, idx in kind.values { if (cast(^uintptr)data)^ == cast(uintptr)v { current_item_index = cast(i32)idx; break; } }
                            case: panic(tprint(kind.values[0]));
                        }

                        item := current_item_index;
                        edited |= imgui.combo(name, &item, kind.names, cast(i32)min(5, len(kind.names)));
                        if item != current_item_index {
                            switch kind.base.id {
                                case u8:        (cast(^u8     )data)^ = cast(u8     )kind.values[item];
                                case u16:       (cast(^u16    )data)^ = cast(u16    )kind.values[item];
                                case u32:       (cast(^u32    )data)^ = cast(u32    )kind.values[item];
                                case u64:       (cast(^u64    )data)^ = cast(u64    )kind.values[item];
                                case uint:      (cast(^uint   )data)^ = cast(uint   )kind.values[item];
                                case i8:        (cast(^i8     )data)^ = cast(i8     )kind.values[item];
                                case i16:       (cast(^i16    )data)^ = cast(i16    )kind.values[item];
                                case i32:       (cast(^i32    )data)^ = cast(i32    )kind.values[item];
                                case i64:       (cast(^i64    )data)^ = cast(i64    )kind.values[item];
                                case int:       (cast(^int    )data)^ = cast(int    )kind.values[item];
                                case rune:      (cast(^rune   )data)^ = cast(rune   )kind.values[item];
                                case uintptr:   (cast(^uintptr)data)^ = cast(uintptr)kind.values[item];
                                case: panic(tprint(kind));
                            }
                        }
                    }
                }
                case runtime.Type_Info_Quaternion: {}
                case runtime.Type_Info_String: {
                    if tags == "" {
                        text_edit_buffer: [256]u8;
                        bprint(text_edit_buffer[:], (cast(^string)data)^);

                        if imgui.input_text(name, text_edit_buffer[:], .EnterReturnsTrue) {
                            result := text_edit_buffer[:];
                            for b, i in text_edit_buffer {
                                if b == '\x00' {
                                    result = text_edit_buffer[:i];
                                    break;
                                }
                            }
                            str := strings.clone(cast(string)result);
                            (cast(^string)data)^ = str; // @Leak
                        }
                    } else {
                        draw_resource_combo :: proc(name: string, data: rawptr, m: $T/map[string]$E) -> bool{
                            selection := (cast(^string)data)^;
                            if !imgui.begin_combo(name, selection) do return false;
                            defer imgui.end_combo();

                            edited := false;
                            for k, _ in m {
                                if imgui.selectable(k, selection == k) {
                                    (cast(^string)data)^ = k;
                                    edited = true;
                                }
                            }
                            return edited;
                        }
                        if strings.contains(tags, "model") {
                            edited |= draw_resource_combo(name, data, wb.g_models);
                        }

                        if strings.contains(tags, "material") {
                            edited |= draw_resource_combo(name, data, wb.g_materials);
                        }

                        if strings.contains(tags, "texture") {
                            edited |= draw_resource_combo(name, data, wb.g_textures);
                        }
                    }
                }

                case runtime.Type_Info_Named: {
                    edited |= auto_field_gen(name, kind.base, data, tags);
                }
                case runtime.Type_Info_Struct: {
                    base_ptr := data;
                    for field, i in kind.names {
                        edited |= auto_field_gen(field, kind.types[i], rawptr(uintptr(base_ptr)+kind.offsets[i]), kind.tags[i], false);
                    }
                }
                
                case runtime.Type_Info_Slice: {}
                case runtime.Type_Info_Array: {
                    if strings.contains(tags, "colour") {
                        assert(kind.elem_size == 4);
                        assert(kind.elem == type_info_of(f32));

                        imgui.push_id(name);
                        defer imgui.pop_id();


                        col := mem.slice_ptr(cast(^f32) data, 4);
                        if imgui.color_button(name, imgui.Vec4{col[0], col[1], col[2], col[3]}, .None, imgui.Vec2{75, 20}) {
                            imgui.open_popup("colour_picker");
                            edited = true;
                        }
                        imgui.same_line();
                        imgui.text(name);

                        if imgui.begin_popup("colour_picker", .NoTitleBar | .NoResize | .NoDocking) {
                            imgui.color_picker4(name, cast(^f32) data);
                            imgui.end_popup();
                        }
                    }
                }
                case runtime.Type_Info_Dynamic_Array: {}
                case runtime.Type_Info_Map: {}
                
                case runtime.Type_Info_Tuple: {}
                case runtime.Type_Info_Any: {}
                case runtime.Type_Info_Union: {}
                case runtime.Type_Info_Type_Id: {}
            }

            if !is_root do imgui.unindent();
            return false;
        }

        ti := reflection.get_union_type_info(selected_entity.kind);
        assert(ti != nil);
        struct_ti : runtime.Type_Info_Struct;
        #partial switch kind in ti.variant {
            case runtime.Type_Info_Named: {
                struct_ti = kind.base.variant.(runtime.Type_Info_Struct);
            }
            case runtime.Type_Info_Struct: {
                struct_ti = kind;
            }
            case: log_info("Unhandled type: ", kind);
        }

        base_ptr := &selected_entity.kind;
        for field, i in struct_ti.names {
            auto_field_gen(field, struct_ti.types[i], rawptr(uintptr(base_ptr)+struct_ti.offsets[i]), struct_ti.tags[i]);
        }

        // Entity types can sub their own editors in, if they want special things
        // otherwise generic, and uses tags on fields to modify things

    } imgui.end();

    // TODO edited scene
    if edited do entity.dirty_scene();
}

DEFAULT_TREE_FLAGS : imgui.Tree_Node_Flags : .OpenOnArrow | .SpanAvailWidth | .OpenOnDoubleClick;
DEFAULT_WINDOW_FLAGS : imgui.Window_Flags = .NoCollapse;

g_hierarchy_window_hovered := false;
draw_scene_hierarchy :: proc(userdata: rawptr, open: ^bool) {
    open := imgui.begin("Hierarchy", open, DEFAULT_WINDOW_FLAGS);
    defer imgui.end();
    if !open do return;

    draw_entity_node :: proc(e: ^Entity) {
        assert(e != nil);

        flags := DEFAULT_TREE_FLAGS;
        
        if is_entity_selected(e) do flags |= .Selected;
        if len(e.children) == 0 do flags |= .Leaf;
        
        open := imgui.tree_node_ex(e.name, flags);
        if imgui.begin_drag_drop_source() {
            imgui.set_drag_drop_payload("entity", &e.id, size_of(e.id));
            imgui.text(e.name);
            imgui.end_drag_drop_source();
        }
        if imgui.begin_drag_drop_target() {
            payload := imgui.accept_drag_drop_payload("entity");
            if payload != nil {
                dropped_eid := (cast(^int)payload.data)^;
                entity.set_parent(dropped_eid, e.id);
                imgui.end_drag_drop_target();
            }
        }

        if !open do return;
        defer imgui.tree_pop();
        if imgui.is_item_clicked() {
            select_entity(e.id);
        }
        if e.children != nil {
            for c in &e.children {
                draw_entity_node(c);
            }
        }
    }

    for scene_id, scene in entity.loaded_scenes {
        flags : imgui.Tree_Node_Flags = .OpenOnArrow | .SpanAvailWidth;
        open := imgui.tree_node_ex(tprint(scene_id, (scene.dirty ? " *" : "")), flags);
        
        if imgui.begin_popup_context_item("scene context") {

            if imgui.menu_item("Save") do
                entity.save_scene(scene_id);

            if imgui.menu_item("Add Entity") do
                open_modal("Select Entity");

            imgui.end_popup();
        }

        if !open do continue;
        defer imgui.tree_pop();

        for eid, e in scene.entities {
            if !e.active do continue;
            if e.parent != nil do continue;
            draw_entity_node(e);
        }
    }

    flags := DEFAULT_TREE_FLAGS;
    if imgui.tree_node_ex("Dynamic Entities", flags) {

        if imgui.begin_drag_drop_target() {
            payload := imgui.accept_drag_drop_payload("entity");
            dropped_eid := (cast(^int)payload.data)^;
            entity.add_entity_to_scene(entity.get_entity(dropped_eid));
            imgui.end_drag_drop_target();
        }

        for e in &entity.all_entities {
            if !e.active do continue;
            if e.parent != nil do continue;
            if !e.dynamically_spawned do continue;
            draw_entity_node(&e);
        }
        imgui.tree_pop();
    }

    g_hierarchy_window_hovered = imgui.is_window_hovered();
}

RESOURCES_DIR :: "resources/";
selected_resource: string;
draw_resource_inspector :: proc(userdata: rawptr, open: ^bool) {
    profiler.TIMED_SECTION();
    open := imgui.begin("Resources", open, DEFAULT_WINDOW_FLAGS);

    defer imgui.end();
    if !open do return;

    draw_path :: proc(path: basic.Path) {
        flags := DEFAULT_TREE_FLAGS;
        if path.path == selected_resource do flags |= .Selected;
        if !path.is_directory do flags |= .Leaf;

        node_open := imgui.tree_node_ex(path.file_name, flags);

        if imgui.begin_drag_drop_source() {
            path := path;
            imgui.set_drag_drop_payload("resource", &path, size_of(path));
            imgui.text(path.file_name);
            imgui.end_drag_drop_source();
        }

        if imgui.begin_drag_drop_target() {
            payload := imgui.accept_drag_drop_payload("entity");
            if payload != nil {
                // TODO prefab creation
            }
            imgui.end_drag_drop_target();
        }

        if imgui.is_item_clicked() {
            selected_resource = path.path;
        }

        if !node_open do return;
        defer imgui.tree_pop();

        if path.is_directory {
            paths := basic.get_all_paths(path.path);
            defer delete(paths);
            for path in paths {
                draw_path(path);
            }
        }
    }

    paths := basic.get_all_paths(RESOURCES_DIR);
    defer delete(paths);
    for path in paths {
        draw_path(path);
    }
}

g_game_view_texture: wb.Texture;
g_can_move_game_view: bool;
g_clicked_outside_scene: bool;
g_game_view_mouse_pos: Vector2;
g_game_view_window_hovered := false;

draw_game_view :: proc(userdata: rawptr, open: ^bool) {
    flags := DEFAULT_WINDOW_FLAGS | .NoTitleBar;
    open := imgui.begin("Game View", open, flags);
    defer imgui.end();
    if !open do return;

    g_can_move_game_view = imgui.is_window_hovered();

    window_size := imgui.get_window_size();
    window_pos := imgui.get_window_pos();

    target_width := window_size.x;
    target_height := window_size.y;

    current_width := cast(f32) shared.WINDOW_SIZE_X;
    current_height := cast(f32) shared.WINDOW_SIZE_Y;

    width := target_width;
    height := target_height;

    image_ar := current_width / current_height;
    target_ar := target_width / target_height;

    if image_ar > target_ar { // taller than what we want
        height = target_width / image_ar;
    } else if image_ar < target_ar { // wider than what we want
        width = target_height * image_ar;
    }

    // TODO center image in window

    if g_game_view_texture.type != .Invalid {
        imgui.image(cast(imgui.Texture_ID)&g_game_view_texture, {width, height});

        if imgui.begin_drag_drop_target() {
            payload := imgui.accept_drag_drop_payload("resource");
            if payload != nil {
                resource_path := cast(^basic.Path) payload.data;
                tid: typeid;
                spawned_entity: ^Entity;
                switch resource_path.extension {
                    case "fbx": {
                        tid = typeid_of(entity.Simple_Model);
                        
                        created_entity := entity.create_entity_by_type(tid); 
                        spawned_entity = entity.add_entity(created_entity, true);
                        entity.add_entity_to_scene(spawned_entity);
                        
                        // TODO try place between camera and object. With max dist away from cam
                        camera_direction := wb.get_mouse_direction_from_camera(&g_editor_camera, {0.5,0.5});
                        spawned_entity.position = g_editor_camera.position + camera_direction * 10;
                    }
                    case "pfb": {
                        // TODO
                    }
                    case: log.error("Unhandled resource type: ", resource_path.extension);
                }
                
                if spawned_entity != nil {
                    switch kind in &spawned_entity.kind {
                        case entity.Simple_Model: {
                            fname, _ := basic.get_file_name(resource_path.file_name);
                            // @leak
                            kind.model_id = strings.clone(fname);
                            
                        }

                        case entity.Player_Character: break;
                        case entity.Directional_Light: break;
                        case entity.Enemy: break;
                    }
                }
            }

            imgui.end_drag_drop_target();
        }

        p_min, p_max: imgui.Vec2;
        imgui.get_item_rect_min(&p_min); imgui.get_item_rect_max(&p_max);

        x_scale := shared.WINDOW_SIZE_X / width;
        y_scale := shared.WINDOW_SIZE_Y / height;

        wb_pixel_pos := wb.main_window.mouse_position_pixel;
        g_game_view_mouse_pos.x = (wb_pixel_pos.x - window_pos.x) * x_scale;
        g_game_view_mouse_pos.y = (wb_pixel_pos.y - (shared.WINDOW_SIZE_Y - p_max.y) + p_min.y + 15) * y_scale;

        imgui.draw_list_add_image(imgui.get_window_draw_list(), cast(imgui.Texture_ID)&gizmo_color_buffer, p_min, p_max);
    }

    g_game_view_window_hovered = imgui.is_window_hovered();
}

DEBUG_COLOURS := [4]imgui.Vec4 {{52/255.0, 152/255.0, 219/255.0, 1}, {241/255.0, 196/255.0, 15/255.0, 1}, {230/255.0, 126/255.0, 34/255.0, 1}, {231/255.0, 76/255.0, 60/255.0, 1}};
levels := map[log.Level]bool { log.Level.Debug = true, log.Level.Info = true, log.Level.Warning = true, log.Level.Error = true };

draw_console :: proc(userdata: rawptr, open: ^bool) {
    using imgui;

    // show_demo_window();

    open := begin("Console", open, DEFAULT_WINDOW_FLAGS);
    defer end();
    if !open do return;

    @static search_buffer: [256]byte;
    input_text("Filter", search_buffer[:]);

    for level, enabled in levels {
        same_line();
        debug_icon_texture := wb.g_textures["Help-Circle-Icon.png"];
        bg_col := get_style_color_vec4(enabled ? .ButtonHovered : .Button);
        if image_button(user_texture_id=cast(Texture_ID)debug_icon_texture, size={10, 10}, tint_col=DEBUG_COLOURS[(cast(uint)level)/10], bg_col=bg_col^) {
            levels[level] = !enabled;
        }
    }

    footer_height_to_reserve := get_style().item_spacing.y + get_frame_height_with_spacing();
    begin_child("ScrollRegion", Vec2{0, -footer_height_to_reserve}, false, .HorizontalScrollbar);
    push_style_var(.ItemSpacing, Vec2{4, 1});
    for item in util.logs {
        // TODO filter

        push_style_color(.Text, DEBUG_COLOURS[(cast(uint)item.severity)/10]);
        defer pop_style_color();
        text_unformatted(item.message);
    }

    // if (scroll_to_bottom || (AutoScroll && GetScrollY() >= GetScrollMaxY()))
    //     SetScrollHereY(1.0f);
    // scroll_to_bottom = false;

    pop_style_var();
    end_child();

}

// Modals
draw_entity_select_modal :: proc(modal: ^Modal, userdata: rawptr) {

    @static selected_tid : typeid;

    imgui.list_box_header("");
    for tid in entity.entity_typeids {
        selected := tid == selected_tid;
        if imgui.selectable(fmt.tprint(tid), selected) {
            selected_tid = tid;
        }
    }
    imgui.list_box_footer();

    if imgui.button("Create") {
        created_entity := entity.create_entity_by_type(selected_tid);
        camera_direction := wb.get_mouse_direction_from_camera(&g_editor_camera, {0.5,0.5});
        // TODO maybe entity creation window to set certain parameters?
        // TODO try place between camera and object. With max dist away from cam
        pos := g_editor_camera.position + camera_direction * 10;
        spawned_entiy := entity.add_entity(created_entity, true);
        entity.add_entity_to_scene(spawned_entiy);
        spawned_entiy.position = pos;
        modal.is_open = false;
    }
    imgui.same_line();
    if imgui.button("Cancel") {
        modal.is_open = false;
    }
}


//
//

selected_entities: [dynamic]int;

select_entity :: proc(eid: int, override_selection: bool = true) {
    if override_selection {
        clear(&selected_entities);
    }

    if eid > 0 {
        for e in selected_entities {
            if e == eid do return;
        }
        append(&selected_entities, eid);
    }
}

is_entity_selected :: proc(e: ^Entity) -> bool {
    for se in selected_entities {
        if se == e.id do return true;
    }
    return false;
}


//
//
Modal :: struct {
    name: string,
    procedure: proc(^Modal, rawptr),
    userdata: rawptr,
    is_open: bool,

    action: proc(userdata: rawptr, modal_data: rawptr),
}

modals: [dynamic]Modal;

register_modal :: proc(name: string, procedure: proc(^Modal, rawptr), userdata: rawptr, action: proc(userdata: rawptr, modal_data: rawptr) = nil) {
    append(&modals, Modal{name, procedure, userdata, false, action});
}

open_modal :: proc(name: string) {
    for modal in &modals {
        if modal.name == name {
            modal.is_open = true;
            break;
        }
    }
}

close_modal :: proc(name: string) {
    for modal in &modals {
        if modal.name == name {
            modal.is_open = false;
            break;
        }
    }
}



Draw_Command :: shared.Draw_Command;
Entity :: entity.Entity;

tprint   :: fmt.tprint;
tprintf  :: fmt.tprintf;
tprintln :: fmt.tprintln;
aprint   :: fmt.aprint;
aprintf  :: fmt.aprintf;
aprintln :: fmt.aprintln;
bprint   :: fmt.bprint;
bprintf  :: fmt.bprintf;
bprintln :: fmt.bprintln;
print   :: fmt.print;
printf  :: fmt.printf;
println :: fmt.println;
sbprint   :: fmt.sbprint;
sbprintf  :: fmt.sbprintf;
sbprintln :: fmt.sbprintln;
panicf :: fmt.panicf;

log_info :: util.log_info;
log_debug :: util.log_debug;
log_warn :: util.log_warn;
log_error :: util.log_error;

Vector2 :: wb.Vector2;
Vector3 :: wb.Vector3;
Vector4 :: wb.Vector4;
Quaternion :: wb.Quaternion;
Matrix4 :: wb.Matrix4;

TAU :: math.TAU;
PI  :: math.PI;

pow                :: math.pow;
to_radians         :: math.to_radians_f32;
to_radians_f64     :: math.to_radians_f64;
to_degrees         :: math.to_degrees_f32;
to_degrees_f64     :: math.to_degrees_f64;
ortho3d            :: la.matrix_ortho3d;
perspective        :: la.matrix4_perspective;
transpose          :: la.transpose;
translate          :: la.matrix4_translate;
mat4_scale         :: la.matrix4_scale;
mat4_inverse       :: la.matrix4_inverse;
quat_to_mat4       :: la.matrix4_from_quaternion;
mul                :: la.mul;
length             :: la.length;
norm               :: la.normalize;
dot                :: la.dot;
cross              :: la.cross;
asin               :: math.asin;
acos               :: math.acos;
atan               :: math.atan;
atan2              :: math.atan2;
floor              :: math.floor;
ceil               :: math.ceil;
cos                :: math.cos;
sin                :: math.sin;
sqrt               :: math.sqrt;
slerp              :: la.quaternion_slerp;
quat_norm          :: la.quaternion_normalize;
angle_axis         :: la.quaternion_angle_axis;
identity           :: la.identity;
quat_inverse       :: la.quaternion_inverse;
lerp               :: math.lerp;
quat_mul_vec3      :: la.quaternion_mul_vector3;
mod                :: math.mod;

to_vec2 :: basic.to_vec2;
to_vec3 :: basic.to_vec3;
to_vec4 :: basic.to_vec4;
pretty_location :: basic.pretty_location;

quaternion_right   :: wb.quaternion_right;
quaternion_up      :: wb.quaternion_up;
quaternion_forward :: wb.quaternion_forward;
quaternion_left    :: wb.quaternion_left;
quaternion_down    :: wb.quaternion_down;
quaternion_back    :: wb.quaternion_back;