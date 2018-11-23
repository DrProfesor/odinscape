package main

using import    "core:fmt"
using import    "core:math"
	  import    "core:mem"

using import _ "key_config";

	  import wb "shared:workbench"
	  import ai "shared:workbench/external/assimp"
	  import coll "shared:workbench/collision"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Workspace{"Main", main_init, main_update, main_render, main_end}, &gameplay_camera);
}

cube_model: wb.Model;

main_collision_scene: coll.Collision_Scene;

guy_entity: Entity;

gameplay_camera := wb.Camera{true, 85, {}, {}, {}};

main_init :: proc() {
	init_entities();
	init_key_config();

	cube_model = wb.load_asset("resources/Models/cube.fbx");
	gronk_model := wb.load_asset("resources/Models/gronk.obj");
	gronk_tex := wb.load_texture("resources/Textures/OrcGreen.png");

	make_terrain_entity(Vec3{0, -7, 0});
	guy_entity = make_unit_entity(Vec3{0, -6, 0}, gronk_model, gronk_tex);
	focus_camera_on_guy(guy_entity);
}

make_terrain_entity :: proc(position: Vec3) -> Entity {
	e := new_entity();
	add_component(e, Transform{{}, position, {10, 1, 10}, {}, {}});
	add_component(e, Mesh_Renderer{{}, cube_model, {}, 0, wb.shader_rgba_3d});
	add_component(e, box_collider_identity());
	return e;
}

make_unit_entity :: proc(position: Vec3, model: wb.Model, texture: wb.Texture) -> Entity {
	e := new_entity();
	add_component(e, Transform{{}, position, {1, 1, 1}, {}, {}});
	add_component(e, Mesh_Renderer{{}, model, Vec3{0, 0.5, 0}, texture, wb.shader_texture});
	add_component(e, Unit_Component{{}, 5, {}});
 	return e;
}

focus_camera_on_guy :: proc(e: Entity) {
	tf := get_component(e, Transform);
	assert(tf != nil);

	gameplay_camera.position = tf.position + Vec3{0, 7, 5};
	gameplay_camera.rotation = Vec3{300, 0, 0};

	wb.update_view_matrix(&gameplay_camera);
	free_camera = false;
}

last_mouse_pos: Vec2;
main_update :: proc(dt: f32) {
    if wb.get_input_down(wb.Input.Escape) do wb.end_workspace(wb.current_workspace);

	update_entities();
    update_camera();
    update_inspector_window();
}

free_camera: bool;

update_camera :: proc() {
	if wb.get_input_down(key_config.camera_snap_to_unit) {
		focus_camera_on_guy(guy_entity);
	}

	if wb.get_input_down(key_config.free_camera) {
		free_camera = true;
	}

    camera_orientation := wb.degrees_to_quaternion(gameplay_camera.rotation);

    up      := Vec3{0,  1,  0};
    down    := Vec3{0, -1,  0};
    forward := Vec3{0,  0, -1};
	right   := Vec3{1,  0,  0};

    if free_camera {
	    forward = wb.quaternion_forward(camera_orientation);
	    right   = wb.quaternion_right(camera_orientation);
    }

    back := -forward;
    left := -right;

	SPEED :: 10;

	if wb.get_input(key_config.camera_up)      { gameplay_camera.position += up      * SPEED * wb.fixed_delta_time; }
	if wb.get_input(key_config.camera_down)    { gameplay_camera.position += down    * SPEED * wb.fixed_delta_time; }
	if wb.get_input(key_config.camera_forward) { gameplay_camera.position += forward * SPEED * wb.fixed_delta_time; }
	if wb.get_input(key_config.camera_back)    { gameplay_camera.position += back    * SPEED * wb.fixed_delta_time; }
	if wb.get_input(key_config.camera_left)    { gameplay_camera.position += left    * SPEED * wb.fixed_delta_time; }
	if wb.get_input(key_config.camera_right)   { gameplay_camera.position += right   * SPEED * wb.fixed_delta_time; }

	wb.update_view_matrix(&gameplay_camera);

	if !free_camera {
		if wb.get_input_down(key_config.camera_enable_mouse_rotation) {
			hits: [dynamic]coll.Hit_Info;
			defer delete(hits);

			cursor_direction := wb.get_cursor_direction_from_camera(&gameplay_camera);
			coll.linecast(&main_collision_scene, gameplay_camera.position, gameplay_camera.position + cursor_direction * 1000, &hits);
			for hit in hits {
				unit := get_component(guy_entity, Unit_Component);
				unit.has_target = true;
				unit.current_target = hit.point0;
			}
		}
	}
	else {
		if wb.get_input(key_config.move_command) {
			mouse_delta := wb.cursor_screen_position - last_mouse_pos;
			SENSITIVITY :: 0.1;
			mouse_delta *= SENSITIVITY;
			gameplay_camera.rotation += Vec3{mouse_delta.y, -mouse_delta.x, 0};
			wb.update_view_matrix(&gameplay_camera);
		}
	}
	last_mouse_pos = wb.cursor_screen_position;
}

main_render :: proc(dt: f32) {
	render_entities();
	wb.im_flush_3d();
}

main_end :: proc() {
	shutdown_entities();
	key_config_save();
}