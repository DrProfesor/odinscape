package main

using import    "core:fmt"
using import    "core:math"
	  import    "core:mem"

	  import wb "shared:workbench"
	  import ai "shared:workbench/external/assimp"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Scene{"Main", main_init, main_update, main_render, main_end});
}

cube_mesh_ids: [dynamic]wb.MeshID;

main_init :: proc() {
	wb.perspective_camera(85);
	init_entities();
	wb.camera_position = Vec3{0, 0, -10};

	cube_mesh_ids = wb.load_asset("resources/Models/cube.fbx");

	mesh_entity := new_entity();
	add_component(mesh_entity, identity_transform());
	add_component(mesh_entity, Mesh_Renderer{{}, cube_mesh_ids});
	add_component(mesh_entity, Sprite_Renderer{{}, wb.random_color()});
	add_component(mesh_entity, Spinner_Component{{}, 5, 2, wb.random_vec3() * 1});

	other_entity := new_entity();
	add_component(other_entity, identity_transform());
	add_component(other_entity, Mesh_Renderer{{}, cube_mesh_ids});
	add_component(other_entity, Spinner_Component{{}, 0, 0, wb.random_vec3() * 0.5});
}

last_mouse_pos: Vec2;
main_update :: proc(dt: f32) {
    if wb.get_key_down(wb.Key.Escape) do wb.exit();

    if wb.get_key(wb.Key.Space) do wb.camera_position.y += 0.1;
	if wb.get_key(wb.Key.Left_Control) do wb.camera_position.y -= 0.1;
	if wb.get_key(wb.Key.W) do wb.camera_position.z += 0.1;
	if wb.get_key(wb.Key.S) do wb.camera_position.z -= 0.1;
	if wb.get_key(wb.Key.A) do wb.camera_position.x += 0.1;
	if wb.get_key(wb.Key.D) do wb.camera_position.x -= 0.1;

	if wb.get_mouse(wb.Mouse.Right)
	{
		mouse_delta := wb.cursor_screen_position - last_mouse_pos;
		sensitivity : f32 = 0.1;
		mouse_delta *= sensitivity;
		wb.camera_rotation += Vec3{-mouse_delta.y, mouse_delta.x,0};
	}
	last_mouse_pos = wb.cursor_screen_position;

	update_entities();
}

main_render :: proc(dt: f32) {
	wb.use_program(wb.shader_rgba_3d);
	render_entities();
}

main_end :: proc() {
	shutdown_entities();
}