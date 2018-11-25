package main

using import "core:fmt"
using import "core:math"
	  import "core:mem"
	  import "core:os"

using import _ "key_config";

	  import wb "shared:workbench"
	  import coll "shared:workbench/collision"
	  import ai "shared:workbench/external/assimp"
	  import imgui "shared:workbench/external/imgui"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Workspace{"Main", main_init, main_update, main_render, main_end}, &gameplay_camera);
}

cube_model: wb.Model;

main_collision_scene: coll.Collision_Scene;

gameplay_camera := wb.Camera{true, 85, {}, {}, {}};

main_init :: proc() {
	init_entities();
	init_key_config();

	cube_model = wb.load_asset_to_gpu("resources/Models/cube.fbx");
	gronk_model := wb.load_asset_to_gpu("resources/Models/gronk.obj");

	gronk_tex_data, ok := os.read_entire_file("resources/Textures/OrcGreen.png");
	assert(ok);
	defer delete(gronk_tex_data);
	gronk_tex := wb.load_texture(gronk_tex_data);

	make_terrain_entity(Vec3{0, -7, 0});
	guy_entity = make_unit_entity(Vec3{0, -6, 0}, gronk_model, gronk_tex);
	focus_camera_on_guy(guy_entity);
}

make_terrain_entity :: proc(position: Vec3) -> Entity {
	e := new_entity("Terrain");
	add_component(e, Transform{{}, position, {10, 1, 10}, {}, {}});
	add_component(e, Mesh_Renderer{{}, cube_model, {}, 0, wb.shader_rgba_3d});
	add_component(e, box_collider_identity());
	return e;
}

make_unit_entity :: proc(position: Vec3, model: wb.Model, texture: wb.Texture) -> Entity {
	e := new_entity("Unit");
	add_component(e, Transform{{}, position, {1, 1, 1}, {}, {}});
	add_component(e, Mesh_Renderer{{}, model, Vec3{0, 0.5, 0}, texture, wb.shader_texture});
	add_component(e, Unit_Component{{}, 5, {}});
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