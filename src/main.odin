package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"
import wb        "shared:workbench"
import platform  "shared:workbench/platform"

using import "editor"

main_init :: proc() {
	//
	init_key_config();
    
    //
    game_init();
    
}

main_update :: proc(dt: f32) {
    if platform.get_input_down(platform.Input.Escape) do wb.end_workspace(wb.current_workspace);
    
    //
    game_update(dt);
    
    //
    editor_update(dt);
}

main_render :: proc(dt: f32) {
    game_render();
}

main_end :: proc() {
	key_config_save();
	game_end();
}

debug_window_proc :: proc(_: rawptr) {
	//imgui.checkbox("Debug Colliders", &debugging_colliders);
	//imgui.checkbox("Entity Handles", &debug_draw_entity_handles);
	//imgui.checkbox("Ability Editor", &ability_manager.show_ability_editor);
}

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, 
                          wb.Workspace{"Main", main_init, main_update, main_render, main_end});
}

