package main

using import    "core:fmt"
using import    "core:math"
using import _ "key_config";

	  import coll "shared:workbench/collision"
	  import wb "shared:workbench"

guy_entity: Entity;

free_camera: bool;

update_player_input :: proc() {
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
		if wb.get_input_down(key_config.move_command) {
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
		if wb.get_input(key_config.camera_enable_mouse_rotation) {
			mouse_delta := wb.cursor_screen_position - last_mouse_pos;
			SENSITIVITY :: 0.1;
			mouse_delta *= SENSITIVITY;
			gameplay_camera.rotation += Vec3{mouse_delta.y, -mouse_delta.x, 0};
			wb.update_view_matrix(&gameplay_camera);
		}
	}
	last_mouse_pos = wb.cursor_screen_position;
}

focus_camera_on_guy :: proc(e: Entity) {
	tf := get_component(e, Transform);
	assert(tf != nil);

	gameplay_camera.position = tf.position + Vec3{0, 7, 5};
	gameplay_camera.rotation = Vec3{300, 0, 0};

	wb.update_view_matrix(&gameplay_camera);
	free_camera = false;
}