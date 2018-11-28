package main

using import "core:fmt"
using import "core:math"
	  import "core:mem"
	  import "core:os"

	  import wb "shared:workbench"
	  import coll "shared:workbench/collision"
	  import ai "shared:workbench/external/assimp"
	  import imgui "shared:workbench/external/imgui"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Workspace{"Main", main_init, main_update, main_render, main_end}, &gameplay_camera);
}

cube_model: ^Model_Asset;

main_collision_scene: coll.Collision_Scene;
scene : Scene;

gameplay_camera := wb.Camera{true, 85, {}, {}, {}};

main_init :: proc() {
	init_entities();
	init_key_config();
	scene = scene_init("main");

	gronk_model := get_model("gronk");

	cube_model = get_model("cube");
	gronk_tex := get_texture("gronk_texture");

	make_entity_terrain(Vec3{0, -0.5, 0});
	player_entity = make_entity_unit(Vec3{-3, 0, -3}, gronk_model, gronk_tex);
	add_selected_unit(player_entity);
	focus_camera_on_guy(player_entity);

	make_entity_unit(Vec3{ 3, 0, -3}, gronk_model, gronk_tex);
	make_entity_unit(Vec3{-3, 0,  3}, gronk_model, gronk_tex);
	make_entity_training_dummy(Vec3{ 3, 0,  3}, cube_model);

	wb.client_debug_window_proc = debug_window_proc;
}

make_entity_terrain :: proc(position: Vec3) -> Entity {
	e := new_entity("Terrain");
	add_component(e, transform(position, {10, 1, 10}));
	add_component(e, Mesh_Renderer{{}, cube_model, {}, wb.COLOR_BLUE, 0, wb.shader_rgba_3d});
	add_component(e, Terrain_Component);
	add_component(e, box_collider());
	return e;
}

make_entity_unit :: proc(position: Vec3, model: ^Model_Asset, texture: wb.Texture) -> Entity {
	e := new_entity("Unit");
	add_component(e, transform(position));
	add_component(e, Mesh_Renderer{{}, model, {}, wb.COLOR_WHITE, texture, wb.shader_texture});
	add_component(e, unit_component(5, 1, 2, 0.5));
	add_component(e, box_collider({1, 1, 1}, {0, 0.5, 0}));
 	return e;
}

make_entity_training_dummy :: proc(position: Vec3, model: ^Model_Asset) -> Entity {
	e := new_entity("Training Dummy");
	add_component(e, transform(position));
	add_component(e, Mesh_Renderer{{}, model, {0, 0, 0}, wb.COLOR_WHITE, {}, wb.shader_texture});
	add_component(e, box_collider({1, 1, 1}, {0, 0.5, 0}));
	add_component(e, Attack_Default_Command);
	add_component(e, Health_Component{{}, 10});
 	return e;
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
}