package main

using import   "core:fmt"
using import   "core:math"
using import _ "key_config";

	  import coll "shared:workbench/collision"
	  import wb "shared:workbench"

player_entity: Entity;
selected_units: [dynamic]Entity;

free_camera: bool;

cursor_hit_infos: [dynamic]coll.Hit_Info;

update_player_input :: proc() {
	if wb.get_input_down(key_config.camera_snap_to_unit) {
		focus_camera_on_guy(player_entity);
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
		cursor_direction := wb.get_cursor_direction_from_camera(&gameplay_camera);
		coll.linecast(&main_collision_scene, gameplay_camera.position, gameplay_camera.position + cursor_direction * 1000, &cursor_hit_infos);

		if wb.get_input_down(key_config.select_unit) {
			for hit in cursor_hit_infos {
				collider, ok := coll.get_collider(&main_collision_scene, hit.handle);
				assert(ok);

				unit := get_component(cast(Entity)hit.handle, Unit_Component);
				if unit != nil {
					clear_selected_units();
					add_selected_unit(unit.entity);
					break;
				}
			}
		}

		if wb.get_input_down(key_config.move_command) {
			for hit in cursor_hit_infos {
				collider, ok := coll.get_collider(&main_collision_scene, hit.handle);
				assert(ok);
				if get_component(cast(Entity)hit.handle, Terrain_Component) != nil {
					for selected in selected_units {
						unit := get_component(selected, Unit_Component);
						unit.has_target = true;
						unit.current_target = hit.point0;
					}

					break;
				}
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

add_selected_unit :: proc(unit: Entity) {
	append(&selected_units, unit);

	renderer := get_component(unit, Mesh_Renderer);
	assert(renderer != nil);
	renderer.color = wb.COLOR_GREEN;
}

remove_selected_unit_index :: proc(idx: int) {
	unit := selected_units[idx];
	renderer := get_component(unit, Mesh_Renderer);
	assert(renderer != nil);
	renderer.color = wb.COLOR_WHITE;
	wb.remove_at(&selected_units, idx);
}

remove_selected_unit :: proc(unit: Entity) {
	for selected, idx in selected_units {
		if selected == unit {
			remove_selected_unit_index(idx);
		}
	}
}

clear_selected_units :: proc() {
	for len(selected_units) > 0 {
		remove_selected_unit_index(0);
	}
}