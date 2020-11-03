package game

import "core:fmt"

import "shared:wb"
import "shared:wb/basic"

import "../configs"
import "../physics"
import "../net"
import "../shared"
import "../entity"
import "../save"

local_player_save: save.Player_Save;

init_players :: proc() {
	append(&net.on_login_handlers, on_login_players);
}

on_login_players :: proc(player_save: save.Player_Save) {
	local_player_save = player_save;
}

update_players :: proc(dt: f32) {
    for player in entity.all_Player_Character {
        if player.is_local do update_local_player_character(player, dt);
        update_player_character(player, dt);
    }
}

update_local_player_character :: proc(player: ^Player_Character, dt: f32) {

    if wb.get_input_down(configs.key_config.interact) {
        mouse_world := wb.get_mouse_world_position(&g_game_camera, wb.main_window.mouse_position_unit);
        mouse_direction := wb.get_mouse_direction_from_camera(&g_game_camera, wb.main_window.mouse_position_unit);

        player.target_entity = 0;

        @static hits: [dynamic]physics.Raycast_Hit;
        hit_count := physics.raycast(mouse_world, mouse_direction, &hits);
        if hit_count > 0 {
            first_hit := hits[0];
            // TODO is it ground or targetable
            player.target_position = first_hit.hit_pos;
            player.path = physics.smooth_a_star(player.position, first_hit.hit_pos, 1);
            player.path_idx = 1;
            // net.send_new_player_position()
        } 
        // TODO terrain raycasting
        // else {
        //     pos, hit := terrain_get_raycasted_position(mouse_world, mouse_direction);
        //     if hit {
        //         player.target_position = pos;
        //         player.path = physics.smooth_a_star(player_entity.position, pos, 0.5);
        //         player.path_idx = 1;
        //         // net.send_new_player_position()
        //     }
        // }
    }

    // if      plat.get_input(configs.key_config.spell_1) do cast_spell(player, 1);
    // else if plat.get_input(configs.key_config.spell_2) do cast_spell(player, 2);
    // else if plat.get_input(configs.key_config.spell_3) do cast_spell(player, 3);
    // else if plat.get_input(configs.key_config.spell_4) do cast_spell(player, 4);
    // else if plat.get_input(configs.key_config.spell_5) do cast_spell(player, 5);

    // if !wb.debug_window_open {
        // g_game_camera.position = player_entity.position + Vector3{0, 0, -15};
        // // TODO camera rotation?
        // g_game_camera.orientation = wb.direction_to_quaternion(wb.norm(player_entity.position - g_game_camera.position));
    // }
}

update_player_character :: proc(player: ^Player_Character, dt: f32) {
    model, ok := wb.g_models[player.model_id];
    if ok && model.has_bones {
        wb.tick_animation(&player.animator.player, model, dt);
    }
    // if player.model.model_id != player.animator.previous_mesh_id {
    //     wb.init_animation_player(&player.animator.controller.player, model);
    //     player.animator.previous_mesh_id = player.model.model_id;
    // }

    // wb.tick_animation(&player.animator.controller.player, model, dt);

    if wb.length(player.target_position - player.position) > 0.1 {
        next_target_position := player.target_position;
        if player.path_idx < len(player.path)-1 {
            next_target_position = player.path[player.path_idx];
            if wb.length(next_target_position - player.position) < 0.01 {
                player.path_idx += 1;
            }
        }

        height := terrain_get_height_at_position(player.position + {0,2,0}); // add two for player height 
        p1 := move_towards(Vector3{player.position.x, 0, player.position.z}, Vector3{next_target_position.x, 0, next_target_position.z}, player.base_move_speed * dt);

        player.position = {p1.x, height, p1.z};
        player.rotation = wb.degrees_to_quaternion({0, look_y_rot(player.position, next_target_position) - wb.PI / 2, 0});

        // player.animator.controller.player.current_animation = "enter";
    } else {
        // player.animator.controller.player.current_animation = "idle";
    }
    // animate, move
}

look_y_rot :: proc(current, target: Vector3) -> f32 {
    dir := target - current;
    return f32(wb.atan2(f64(dir.z), f64(-dir.x)));
}