package util

import "shared:wb/imgui"
import "shared:wb/logging"


Combo_Filter_State :: struct {
	active_idx: int,
	selection_changed: bool,
}

combo_filter :: proc(label: string, selection: ^string, hints: []string, state: ^Combo_Filter_State, flags: imgui.Combo_Flags) -> bool {

	using imgui;

	state.selection_changed = false;
    logging.logln("");
	window := get_current_window();
	if window.skip_items do return false;

	id := window_get_id(window, label);
	popup_open := is_popup_open(id, Popup_Flags(0));
	should_open := selection^ == hints[state.active_idx];
	just_opened := false;
    logging.logln("");
	g := get_current_context();
	style := g.style;

	arrow_size := (flags & .NoArrowButton) == .NoArrowButton ? 0.0 : get_frame_height();
	label_size : Vec2; calc_text_size(&label_size, label, "", true);
	expected_w := calc_item_width();
	w := (flags & .NoPreview) == .NoPreview ? arrow_size : expected_w;
	frame_bb := Rect{ window.dc.cursor_pos, Vec2{window.dc.cursor_pos.x + w, window.dc.cursor_pos.y + label_size.y + style.frame_padding.y*2.0} };
    total_bb := Rect{ frame_bb.min, Vec2{(label_size.x > 0.0 ? style.item_inner_spacing.x + label_size.x : 0.0) + frame_bb.max.x, frame_bb.max.y} };
    value_x2 := max(frame_bb.min.x, frame_bb.max.x - arrow_size);
    item_size(total_bb, style.frame_padding.y);
    if !item_add(total_bb, id, &frame_bb) do return false;

    hovered, held: bool;
    pressed := button_behavior(frame_bb, id, &hovered, &held);
    logging.logln("");
    if !popup_open {
    	frame_col := get_color_u32(popup_open || hovered ? Col.ButtonHovered : Col.Button);
    	render_nav_highlight(frame_bb, id);
    	logging.logln(frame_bb);
    	logging.logln(id);
    	logging.logln(window.draw_list);
    	if flags & .NoPreview != .NoPreview {
    		draw_list_add_rect_filled(window.draw_list, frame_bb.min, imgui.Vec2{value_x2, frame_bb.max.y}, frame_col, style.frame_rounding, (flags & .NoArrowButton) == .NoArrowButton ? .All : .Left);
        }
    }
    logging.logln("");
    if flags & .NoArrowButton != .NoArrowButton {
		bg_col := get_color_u32((popup_open || hovered) ? imgui.Col.ButtonHovered : imgui.Col.Button);
        text_col := get_color_u32(imgui.Col.Text);
        draw_list_add_rect_filled(window.draw_list, imgui.Vec2{value_x2, frame_bb.min.y}, frame_bb.max, bg_col, style.frame_rounding, (w <= arrow_size) ? .All : .Right);
        if (value_x2 + arrow_size - style.frame_padding.x <= frame_bb.max.x) {
            imgui.render_arrow(window.draw_list, imgui.Vec2{value_x2 + style.frame_padding.y, frame_bb.min.y + style.frame_padding.y}, text_col, .Down, 1.0);
        }
    }
    logging.logln("");
    if !popup_open {
		imgui.render_frame_border(frame_bb.min, frame_bb.max, style.frame_rounding);
        if selection^ != "" && flags & .NoPreview != .NoPreview {
            imgui.render_text_clipped(Vec2{frame_bb.min.x + style.frame_padding.x, frame_bb.min.y + style.frame_padding.y}, imgui.Vec2{value_x2, frame_bb.max.y}, selection^, "", nil, Vec2{0.0,0.0});
        }

        if (pressed || g.nav_activate_id == id || should_open) && !popup_open{
            if window.dc.nav_layer_current == .Main {
                window.nav_last_ids[0] = id;
            }
            open_popup_ex(id);
            popup_open = true;
            just_opened = true;
        }
    }
    logging.logln("");
    if label_size.x > 0 {
    	render_text(Vec2{frame_bb.max.x + style.item_inner_spacing.x, frame_bb.min.y + style.frame_padding.y}, label);
    }

    if !popup_open do return false;
    logging.logln("");
    total_wminus_arrow := w - arrow_size;
    size_callback :: proc(data: ^imgui.Size_Callback_Data) {
        total_wminus_arrow := cast(^f32)data.user_data;
        data.desired_size = Vec2{total_wminus_arrow^, 200};
    }
    set_next_window_size_constraints(Vec2{0 ,0}, Vec2{total_wminus_arrow, 150}, cast(Size_Callback)size_callback, cast(rawptr)&total_wminus_arrow);
    logging.logln("");
    name: string;
    im_format_string(name, uint(len(name)), "##Combo_%02d", g.begin_popup_stack.size); // Recycle windows based on depth

    // Peak into expected window size so we can position it
    popup_window := find_window_by_name(name);
    if popup_window != nil && popup_window.was_active
    {
        size_expected : Vec2; calc_window_expected_size(&size_expected, popup_window);
        if flags & .PopupAlignLeft == .PopupAlignLeft {
            popup_window.auto_pos_last_direction = .Left;
        }
        r_outer : Rect; get_window_allowed_extent_rect(&r_outer, popup_window);
        rect_bl : Vec2; rect_get_bl(&rect_bl, &frame_bb);
        pos : Vec2; find_best_window_pos_for_popup_ex(&pos, rect_bl, size_expected, &popup_window.auto_pos_last_direction, r_outer, frame_bb, .ComboBox);
        
        pos.y -= label_size.y + style.frame_padding.y*2.0;
        
        set_next_window_pos(pos);
    }
    logging.logln("");
    // Horizontally align ourselves with the framed text
    window_flags : Window_Flags = .AlwaysAutoResize | .Popup | .NoTitleBar | .NoResize | .NoSavedSettings;
    //    PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(style.FramePadding.x, style.WindowPadding.y));
    ret := begin(name, nil, window_flags);
    logging.logln("");
    push_item_width(get_window_width());
    set_cursor_pos(Vec2{0, window.dc.curr_line_text_base_offset});
    if just_opened {
        set_keyboard_focus_here(0);
    }
    done := input_text_ex("", "", selection^, i32(len(selection^)), Vec2{0, 0}, .AutoSelectAll | .EnterReturnsTrue, nil, nil);
    pop_item_width();
    logging.logln("");
    if(state.active_idx < 0) {
        return false;
    }
    
    logging.logln("");
    if (!ret) {
        imgui.end_child();
        pop_item_width();
        end_popup();
        return false;
    }
    logging.logln("");
    
    region : Vec2; get_content_region_avail(&region);
    begin_child("ChildL", Vec2{region.x, region.y}, false);

    selection_changed_local := state.selection_changed;
    
    if done {
    	close_current_popup();
    }
    logging.logln("");
    for hint, i in hints {
    	is_selected := i == state.active_idx;
    	if is_selected && (is_window_appearing() || selection_changed_local) {
    		set_scroll_here_y();
    	}
    	if imgui.selectable(hint, is_selected) {
    		state.selection_changed = state.active_idx != i;
    		state.active_idx = i;
    		selection^ = hint;
    		close_current_popup();
    	}
    }
    end_child();
    end_popup();
    logging.logln("");
	return state.selection_changed && hints[state.active_idx] != selection^;
}