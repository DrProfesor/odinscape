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

main_init :: proc() {
	wb.perspective_camera(85);
	init_entities();
	wb.camera_position = Vec3{0, 0, -10};

	cube_mesh_ids := wb.load_asset("resources/Models/cube.fbx");
	gronk_mesh_ids := wb.load_asset("resources/Models/gronk.fbx");

	mesh_entity := new_entity();
	tf := add_component(mesh_entity, identity_transform());
	tf.scale = Vec3{0.5, 0.5, 0.5};
	add_component(mesh_entity, Mesh_Renderer{{}, gronk_mesh_ids});
	add_component(mesh_entity, Texture_Component{{}, wb.load_texture("resources/Textures/OrcGreen_Debug.png")});
	// add_component(mesh_entity, Sprite_Renderer{{}, wb.random_color()});
	// add_component(mesh_entity, Spinner_Component{{}, 0, 0, wb.random_vec3()*0.2});

	terrain := new_entity();
	add_component(terrain, Transform{{}, {0, -7, 0}, {10, 1, 10}, {}});
	add_component(terrain, Mesh_Renderer{{}, cube_mesh_ids});
}

last_mouse_pos: Vec2;
main_update :: proc(dt: f32) {
    if wb.get_key_down(wb.Key.Escape) do wb.exit();

    camera_orientation := wb.degrees_to_quaternion(wb.camera_rotation);

    up      := Vec3{0,  1, 0};
    down    := Vec3{0, -1, 0};
    forward := wb.quaternion_forward(camera_orientation);
    back    := -forward;
    right   := wb.quaternion_right(camera_orientation);
    left    := -right;

    SPEED :: 10;

    if wb.get_key(wb.Key.Space)        do wb.camera_position += up      * SPEED * dt;
	if wb.get_key(wb.Key.Left_Control) do wb.camera_position += down    * SPEED * dt;
	if wb.get_key(wb.Key.W)            do wb.camera_position += forward * SPEED * dt;
	if wb.get_key(wb.Key.S)            do wb.camera_position += back    * SPEED * dt;
	if wb.get_key(wb.Key.A)            do wb.camera_position += left    * SPEED * dt;
	if wb.get_key(wb.Key.D)            do wb.camera_position += right   * SPEED * dt;

	if wb.get_key(wb.Key.Q)            do wb.camera_rotation.y -= 100 * dt;
	if wb.get_key(wb.Key.E)            do wb.camera_rotation.y += 100 * dt;

	if wb.get_mouse(wb.Mouse.Right)
	{
		mouse_delta := wb.cursor_screen_position - last_mouse_pos;
		SENSITIVITY :: 0.1;
		mouse_delta *= SENSITIVITY;
		wb.camera_rotation += Vec3{-mouse_delta.y, mouse_delta.x, 0};
	}
	last_mouse_pos = wb.cursor_screen_position;

	update_entities();
}

main_render :: proc(dt: f32) {
	wb.use_program(wb.shader_texture);
	render_entities();
}

main_end :: proc() {
	shutdown_entities();
}