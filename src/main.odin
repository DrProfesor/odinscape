package main

using import "core:fmt"
using import "core:math"
	  import "core:mem"
	  import "core:os"

using import "shared:workbench/logging"
	  import wb     "shared:workbench"
	  import coll   "shared:workbench/collision"
	  import wbmath "shared:workbench/math"
	  import ai     "shared:workbench/external/assimp"
	  import imgui  "shared:workbench/external/imgui"

cube_model: ^Model_Asset;

main_collision_scene: coll.Collision_Scene;
scene: Scene;

gameplay_camera := wb.Camera{true, 65, {}, {}, {}};

main_init :: proc() {
	//
	load_fonts();
	init_key_config();
	init_entities();
	init_abilities();

	//
	scene = scene_init("main");

	//
	add_selected_unit(player_input_manager.player_entity);
	focus_camera_on_guy(player_input_manager.player_entity);

	//
	wb.client_debug_window_proc = debug_window_proc;
}

last_mouse_pos: Vec2;
main_update :: proc(dt: f32) {
    if wb.get_input_down(wb.Input.Escape) do wb.end_workspace(wb.current_workspace);

    update_player_input();

	update_entities();
    update_inspector_window();
}

main_render :: proc(dt: f32) {
	render_entities();
}

main_end :: proc() {
	scene_end(scene);
	shutdown_entities();
	key_config_save();
}

debug_window_proc :: proc() {
	imgui.checkbox("Debug Colliders", &debugging_colliders);
	imgui.checkbox("Entity Handles", &debug_draw_entity_handles);
	imgui.checkbox("Ability Editor", &ability_manager.show_ability_editor);
}

load_fonts :: proc() {
	data, ok1 := os.read_entire_file("resources/fonts/OpenSans-Regular.ttf");
	assert(ok1);

	ok2: bool;
	wb.font_default, ok2 = wb.load_font(data, 72);
	assert(ok2);
}






main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Workspace{"Main", main_init, main_update, main_render, main_end}, &gameplay_camera);
}

