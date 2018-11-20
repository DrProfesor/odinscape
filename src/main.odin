package main

using import    "core:fmt"
using import    "core:math"
	  import    "core:mem"

	  import wb "shared:workbench"
	  import ai "shared:workbench/external/assimp"
	  import coll "shared:workbench/collision"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Scene{"Main", main_init, main_update, main_render, main_end});
}

cube_mesh_ids: [dynamic]wb.MeshID;

main_collision_scene: coll.Collision_Scene;

guy_entity: Entity;

main_init :: proc() {
	wb.perspective_camera(85);
	init_entities();
	wb.camera_position = Vec3{0, 7.25, -8.5};
	wb.camera_rotation = Vec3{300, 180, 0};

	cube_mesh_ids = wb.load_asset("resources/Models/cube.fbx");
	gronk_mesh_ids := wb.load_asset("resources/Models/gronk.obj");
	gronk_tex := wb.load_texture("resources/Textures/OrcGreen.png");

	mesh_entity := new_entity();
	add_component(mesh_entity, Transform{{}, {0,0,0}, {0.5,0.5,0.5}, {}, {}});
	add_component(mesh_entity, Mesh_Renderer{{}, gronk_mesh_ids, Vec3{0, 0.5, 0}});
	add_component(mesh_entity, Texture_Component{{}, gronk_tex});

	make_terrain_entity(Vec3{0, -7, 0});
	guy_entity = make_guy_entity(Vec3{0, -6, 0});
	make_guy_entity(Vec3{1, -6, 0});
}

make_terrain_entity :: proc(position: Vec3) -> Entity {
	e := new_entity();
	add_component(e, Transform{{}, position, {10, 1, 10}, {}, {}});
	add_component(e, Mesh_Renderer{{}, cube_mesh_ids, {}});
	add_component(e, box_collider_identity());
	return e;
}

make_guy_entity :: proc(position: Vec3) -> Entity {
	e := new_entity();
	add_component(e, Transform{{}, position, {1, 1, 1}, {}, {}});
	add_component(e, Mesh_Renderer{{}, cube_mesh_ids, Vec3{0, 0.5, 0}});
	add_component(e, Unit_Component{{}, 10, {}});
 	return e;
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

	if wb.get_mouse(wb.Mouse.Right)
	{
		mouse_delta := wb.cursor_screen_position - last_mouse_pos;
		SENSITIVITY :: 0.1;
		mouse_delta *= SENSITIVITY;
		wb.camera_rotation += Vec3{mouse_delta.y, -mouse_delta.x, 0};
	}
	last_mouse_pos = wb.cursor_screen_position;

	if wb.get_mouse(wb.Mouse.Left) {
		hits: [dynamic]coll.Hit_Info;
		defer delete(hits);

		cursor_direction := wb.get_cursor_direction_from_camera();
		coll.linecast(&main_collision_scene, wb.camera_position, wb.camera_position + cursor_direction * 1000, &hits);
		for hit in hits {
			unit := get_component(guy_entity, Unit_Component);
			unit.has_target = true;
			unit.current_target = hit.point0;
		}
	}

	SPEED :: 10;

	if wb.get_key(wb.Key.Space)        do wb.camera_position += up      * SPEED * dt;
	if wb.get_key(wb.Key.Left_Control) do wb.camera_position += down    * SPEED * dt;
	if wb.get_key(wb.Key.W)            do wb.camera_position += forward * SPEED * dt;
	if wb.get_key(wb.Key.S)            do wb.camera_position += back    * SPEED * dt;
	if wb.get_key(wb.Key.A)            do wb.camera_position += left    * SPEED * dt;
	if wb.get_key(wb.Key.D)            do wb.camera_position += right   * SPEED * dt;

	if wb.get_key(wb.Key.Q)            do wb.camera_rotation.y -= 100 * dt;
	if wb.get_key(wb.Key.E)            do wb.camera_rotation.y += 100 * dt;

	update_entities();
}

main_render :: proc(dt: f32) {
	wb.use_program(wb.shader_rgba_3d);
	render_entities();
}

main_end :: proc() {
	shutdown_entities();
}