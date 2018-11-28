package main

using import   "core:fmt"
using import   "core:math"

	  import coll "shared:workbench/collision"
	  import wb "shared:workbench"

player_entity: Entity;
selected_units: [dynamic]Entity; // has to be of type Entity because we aren't allowed storing pointers to components

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
		// Get the unit under the cursor
		cursor_direction := wb.get_cursor_direction_from_camera(&gameplay_camera);
		coll.linecast(&main_collision_scene, gameplay_camera.position, gameplay_camera.position + cursor_direction * 1000, &cursor_hit_infos);
		thing_under_cursor: Entity;
		if len(cursor_hit_infos) > 0 {
			hit := cursor_hit_infos[0];
			collider, ok := coll.get_collider(&main_collision_scene, hit.handle);
			assert(ok);
			thing_under_cursor = cast(Entity)hit.handle;
		}

		if unit_under_cursor := get_component(thing_under_cursor, Unit_Component); unit_under_cursor != nil {
			if wb.get_input_down(key_config.select_unit) {
				holding_shift := wb.get_input(key_config.add_unit_to_selection_modifier);
				if !holding_shift {
					clear_selected_units();
				}
				add_selected_unit(unit_under_cursor.entity);
			}
		}

		if wb.get_input_down(key_config.move_command) {
			for hit in cursor_hit_infos {
				collider, ok := coll.get_collider(&main_collision_scene, hit.handle);
				assert(ok);
				hit_entity := cast(Entity)hit.handle;
				if get_component(cast(Entity)hit.handle, Terrain_Component) != nil {
					issue_command(Move_Command{hit.point0});
					break;
				}
				else if get_component(hit_entity, Attack_Default_Command) != nil {
					issue_command(Attack_Command{hit_entity});
					break;
				}
				else {
					issue_command(Approach_Command{hit_entity});
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

issue_command :: proc(command: $T) {
	logln(command);
	holding_shift := wb.get_input(key_config.queue_command_modifier);
	for selected in selected_units {
		unit := get_component(selected, Unit_Component);
		assert(unit != nil);
		if !holding_shift {
			clear(&unit.queued_commands);
		}
		append(&unit.queued_commands, Unit_Command{command});
	}
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