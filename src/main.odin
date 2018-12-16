package main

using import "core:fmt"
using import "core:math"
	  import "core:mem"
	  import "core:os"

	  import wb    "shared:workbench"
	  import coll  "shared:workbench/collision"
	  import ai    "shared:workbench/external/assimp"
	  import imgui "shared:workbench/external/imgui"

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
	gronk_model := get_model("gronk");
	cube_model = get_model("cube");
	gronk_tex := get_texture("gronk_texture");

	//
	make_entity_terrain(Vec3{0, -0.5, 0}, {10, 1, 10});
	make_entity_terrain(Vec3{2.5, 0.5, 2.5}, {5, 1, 5});

	//
	player := make_entity_unit(Vec3{-3, 0, -3}, gronk_model, gronk_tex);
	player_input_manager.player_entity = player;
	add_selected_unit(player);
	focus_camera_on_guy(player);

	//
	make_entity_unit(Vec3{ 3, 0, -3}, gronk_model, gronk_tex);
	make_entity_unit(Vec3{-3, 0,  3}, gronk_model, gronk_tex);
	make_entity_training_dummy(Vec3{ 3, 0,  3}, cube_model);

	//
	wb.client_debug_window_proc = debug_window_proc;
}

make_entity_terrain :: proc(position: Vec3, size: Vec3) -> Entity {
	e := new_entity("Terrain");
	add_component(e, transform(position, size));
	add_component(e, Mesh_Renderer{{}, cube_model, {}, wb.COLOR_BLUE, 0, wb.shader_rgba_3d});
	add_component(e, Terrain_Component);
	add_component(e, box_collider());
	return e;
}

make_entity_unit :: proc(position: Vec3, model: ^Model_Asset, texture: wb.Texture) -> Entity {
	e := new_entity("Unit");
	tf := transform(position);
	tf.stuck_on_ground = true;
	add_component(e, tf);
	add_component(e, Mesh_Renderer{{}, model, {}, wb.COLOR_WHITE, texture, wb.shader_texture});
	add_component(e, health_component(10));
	add_component(e, Attack_Default_Command);
	add_component(e, unit_component(5, 1, 2, 0.5));
	add_component(e, box_collider({1, 1, 1}, {0, 0.5, 0}));
 	return e;
}

make_entity_training_dummy :: proc(position: Vec3, model: ^Model_Asset) -> Entity {
	e := new_entity("Training Dummy");
	tf := transform(position);
	tf.stuck_on_ground = true;
	add_component(e, tf);
	add_component(e, Mesh_Renderer{{}, model, {0, 0.5, 0}, wb.COLOR_WHITE, {}, wb.shader_texture});
	add_component(e, box_collider({1, 1, 1}, {0, 0.5, 0}));
	add_component(e, Attack_Default_Command);
	add_component(e, health_component(100, true));
 	return e;
}

make_entity_projectile :: proc(position: Vec3, direction: Vec3) {
	e := new_entity("Projectile");
	tf := transform(position);
	tf.stuck_on_ground = true;
	tf.offset_from_ground = Vec3{0, 1, 0};
	add_component(e, tf);
	add_component(e, Mesh_Renderer{{}, cube_model, {0, 0, 0}, wb.COLOR_WHITE, {}, wb.shader_texture});
	add_component(e, box_collider({1, 1, 1}, {0, 0.5, 0}));
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

logln :: wb.logln;