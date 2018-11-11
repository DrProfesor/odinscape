package main

using import    "core:fmt"
using import    "core:math"
	  import wb "shared:workbench"
	  import ai "shared:odin-assimp"
	  import        "core:mem"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Scene{"Main", main_init, main_update, main_render, main_end});
}

mesh_entity : Entity;

main_init :: proc() {
	wb.perspective_camera(85);
	init_entities();
	wb.camera_position = Vec3{0, 0, -10};

	mesh_entity = new_entity();
	add_component(mesh_entity, Transform);
	add_component(mesh_entity, Mesh_Renderer);
	add_component(mesh_entity, Sprite_Renderer);
	add_component(mesh_entity, Spinner_Component);

	mesh_comp := get_component(mesh_entity, Mesh_Renderer);
	mesh_comp.mesh_ids = wb.load_asset("Resources/Models/cube.fbx");
}

main_update :: proc(dt: f32) {
    if wb.get_key_down(wb.Key.Escape) do wb.exit();

    if wb.get_key(wb.Key.Space) do wb.camera_position.y += 0.1;
	if wb.get_key(wb.Key.Left_Control) do wb.camera_position.y -= 0.1;
	if wb.get_key(wb.Key.W) do wb.camera_position.z += 0.1;
	if wb.get_key(wb.Key.S) do wb.camera_position.z -= 0.1;
	if wb.get_key(wb.Key.A) do wb.camera_position.x += 0.1;
	if wb.get_key(wb.Key.D) do wb.camera_position.x -= 0.1;

	update_entities();
}

main_render :: proc(dt: f32) {
	wb.use_program(wb.shader_rgba_3d);
	render_entities();
}

main_end :: proc() {
	shutdown_entities();
}