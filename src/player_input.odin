package main

using import   "core:fmt"
using import   "core:math"

	  import coll "shared:workbench/collision"
	  import wb "shared:workbench"

Player_Input_Manager :: struct {
	player_entity: Entity,
	selected_units: [dynamic]Entity, // has to be of type Entity because we aren't allowed storing pointers to components

	free_camera: bool,

	cursor_hit_infos: [dynamic]coll.Hit_Info,
}

player_input_manager: Player_Input_Manager;

update_player_input :: proc() {
	using player_input_manager;

	assert(entity_is_active(player_entity));

	if wb.get_input(key_config.camera_snap_to_unit) {
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
		cursor_position_on_terrain: Vec3;
		found_terrain_position: bool;
		unit_under_cursor: ^Unit_Component; // note(josh): do not store this pointer anywhere!!!!
		{
			cursor_direction := wb.get_cursor_direction_from_camera(&gameplay_camera);
			coll.linecast(&main_collision_scene, gameplay_camera.position, gameplay_camera.position + cursor_direction * 1000, &cursor_hit_infos);
			for hit in cursor_hit_infos {
				e := cast(Entity)hit.handle;
				if !found_terrain_position && get_component(e, Terrain_Component) != nil {
					found_terrain_position = true;
					cursor_position_on_terrain = hit.point0;
				}

				if unit_under_cursor == nil {
					if unit := get_component(e, Unit_Component); unit != nil {
						unit_under_cursor = unit;
					}
				}
			}
		}

		// do abilities
		if len(selected_units) > 0 {
			// todo(josh): better filtering on deciding what the "most important unit" is
			// probably prioritize the player character, things like that. also maybe tabbing
			// through the different unit types?

			unit_abilities, ok := get_most_important_units_abilities();
			if ok {
				for input, ability in unit_abilities {
					if wb.get_input_down(input^) {
						issue_command(Ability_Command{ability, cursor_position_on_terrain, unit_under_cursor != nil ? unit_under_cursor.entity : 0});
					}
				}
			}
		}

		if unit_under_cursor != nil {
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

	draw_player_hud();
}

get_most_important_units_abilities :: inline proc() -> (map[^Game_Input]string, bool) {
	using player_input_manager;

	most_important_unit : ^Unit_Component = get_component(selected_units[0], Unit_Component);
	if most_important_unit == nil do return {}, false;
	return most_important_unit.abilities, true;
}

issue_command :: proc(command: $T) {
	using player_input_manager;

	// logln(command);
	holding_shift := wb.get_input(key_config.queue_command_modifier);
	for selected in selected_units {
		if !entity_is_active(selected) do continue;

		unit := get_component(selected, Unit_Component);
		assert(unit != nil);
		if !holding_shift {
			clear(&unit.queued_commands);
		}
		append(&unit.queued_commands, Unit_Command{command});
	}
}

focus_camera_on_guy :: proc(e: Entity) {
	using player_input_manager;

	tf := get_component(e, Transform);
	assert(tf != nil);

	gameplay_camera.position = tf.position + Vec3{0, 12, 10};
	gameplay_camera.rotation = Vec3{305, 0, 0};

	wb.update_view_matrix(&gameplay_camera);
	free_camera = false;

	select_single_unit(player_entity);
}

select_single_unit :: proc(unit: Entity) {
	clear_selected_units();
	add_selected_unit(unit);
}

add_selected_unit :: proc(unit: Entity) {
	using player_input_manager;

	append(&selected_units, unit);

	renderer := get_component(unit, Mesh_Renderer);
	assert(renderer != nil);
	renderer.color = wb.COLOR_GREEN;
}

remove_selected_unit_index :: proc(idx: int) {
	using player_input_manager;

	unit := selected_units[idx];
	if entity_is_active(unit) {
		renderer := get_component(unit, Mesh_Renderer);
		assert(renderer != nil);
		renderer.color = wb.COLOR_WHITE;
	}

	wb.remove_at(&selected_units, idx);
}

remove_selected_unit :: proc(unit: Entity) {
	using player_input_manager;

	for selected, idx in selected_units {
		if selected == unit {
			remove_selected_unit_index(idx);
		}
	}
}

clear_selected_units :: proc() {
	using player_input_manager;

	for len(selected_units) > 0 {
		remove_selected_unit_index(0);
	}
}



//
// Player HUD
//

draw_player_hud :: proc() {
	wb.ui_push_rect(0.5, 0, 0.5, 0, -150, -300, 0, -300); {
		defer wb.ui_pop_rect();
		wb.ui_draw_colored_quad(wb.Colorf{1, 1, 1, 1});

		unit_abilities, unit_abilities_ok := get_most_important_units_abilities();
		grid := wb.ui_grid_layout(4, 1); {
			defer wb.ui_grid_layout_end();

			idx := 0;
			for input in ([?]^Game_Input{&key_config.ability1, &key_config.ability2, &key_config.ability3, &key_config.ability4}) {
				defer idx += 1;
				defer wb.ui_grid_layout_next(&grid);

				wb.ui_push_rect(0, 0, 1, 1, 20, 20, 20, 20); {
					defer wb.ui_pop_rect();
					wb.ui_draw_colored_quad(wb.Colorf{0.8, 0.8, 0.8, 1});

					if unit_abilities_ok {
						ability_id, ok1 := unit_abilities[input];
						if ok1 {
							ability, ok2 := get_ability(ability_id);
							if ok2 {
								wb.ui_draw_sprite(ability.icon);
							}
						}
					}

					wb.ui_text(wb.font_default, input_to_nice_name(input^), 0.5, wb.COLOR_GREEN);
				}
			}
			assert(idx <= 4);
		}
	}
}








vec3 :: inline proc(x, y: f32) -> Vec3 do return Vec3{x, y, 0};
