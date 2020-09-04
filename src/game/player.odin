package game

import "core:fmt"

import "shared:wb/basic"
import log "shared:wb/logging"
import "shared:wb/types"
import "shared:wb/math"

import "shared:wb"
import plat  "shared:wb/platform"
import wb_math  "shared:wb/math"

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
    for player in entity.player_characters {
        if player.is_local do update_local_player_character(player);
        update_player_character(player);
    }
}

render_players :: proc() {
    for player in entity.player_characters {
        e := cast(^Entity)player;
        
        model := wb.get_model(player.model_id);
        texture := wb.get_texture(player.texture_id);
        shader := wb.get_shader(player.shader_id);

        cmd := wb.create_draw_command(model, shader, e.position, e.scale, e.rotation, player.color, player.material, texture);
        wb.submit_draw_command(cmd);
    }
}

update_local_player_character :: proc(player: ^Player_Character) {
    // update player input
}

update_player_character :: proc(player: ^Player_Character) {
    // animate, move
}

// player_entity_init :: proc(using player: ^Player_Entity) {
//     when #config(HEADLESS, false) {
//         transform, texists := ecs.get_component(e, ecs.Transform);
//         target_position = transform.position;

//         logln("Initting player");

//         model := net.network_add_component(e, Model_Renderer);
//         animator := net.network_add_component(e, Animator);
//         stats := net.network_add_component(e, Stats);
//         health := net.network_add_component(e, Health);
//         caster := net.network_add_component(e, Ability_Caster);

//         player.base_move_speed = 3;
//     } else {
//         net_id, _ := ecs.get_component(e, net.Network_Id);
//         is_local = net_id.controlling_client == net.client_id;
//         if is_local {
//             local_player = e;
//         }

//         base_move_speed = 3;

//         model, mok := ecs.get_component(e, Model_Renderer);
//         assert(mok);
//         model.model_id = "mrknight";
//         model.texture_id = "blue_knight";
//         model.scale = math.Vec3{1, 1, 1};
//         model.color = types.Colorf{1, 1, 1, 1};
//         model.shader_id = "skinning";
//         model.material = wb.Material {
//             0.5,0.5,0.5
//         };

//         animator, aok := ecs.get_component(e, Animator);
//         assert(aok);
//         animator.controller.player.current_animation = "idle";
//     }
// }

// hits: [dynamic]physics.RaycastHit;

// player_entity_update :: proc(using player: ^Player_Character, dt: f32) {
//     when !#config(HEADLESS, false) {
//         if wb.debug_window_open do return;
//     }
    
//     transform, _ := ecs.get_component(e, Transform);
//     animator,  _ := ecs.get_component(e, Animator);
//     net_id,    _ := ecs.get_component(e, net.Network_Id);
//     caster,    _ := ecs.get_component(e, Ability_Caster);

//     final_pos := target_position;
//     if len(player_path) > 0 {
//         final_pos = player_path[len(player_path)-1];
//     }
//     // user input
//     if is_local {
//         if plat.get_input_down(configs.key_config.interact) {
//             mouse_world := wb.get_mouse_world_position(wb.main_camera, plat.main_window.mouse_position_unit);
//             mouse_direction := wb.get_mouse_direction_from_camera(wb.main_camera, plat.main_window.mouse_position_unit);

//             caster.target_entity = 0;

//             // first get non terrain hits
//             // here will be interaction stuff
//             // TODO(jake) select entity
//             hit_count := physics.raycast(mouse_world, mouse_direction, &hits);
//             if hit_count > 0 {
//                 first_hit := hits[0];
//                 enemy, is_enemy := ecs.get_component(first_hit.e, Enemy);
//                 target_transform, _ := ecs.get_component(first_hit.e, Transform);
//                 if is_enemy {
//                     caster.target_entity = first_hit.e;

//                     direction_to_target := math.norm(target_transform.position - transform.position);
//                     distance_to_target := math.magnitude(target_transform.position - transform.position);
//                     target_position = transform.position + direction_to_target * (distance_to_target - 2); // TODO global to configure melee attack distance

//                     player_path = physics.smooth_a_star(transform.position, target_position, 0.5);
//                     path_idx = 1;
//                     net.send_new_player_position(target_position, net_id.network_id);

//                     cast_spell(caster, 0); // Cast the basic attack spell
//                 }
//             } else {     
//                 terrains := ecs.get_component_storage(Terrain);
//                 for terrain in terrains {
//                     terrain_transform, ok := ecs.get_component(terrain.e, Transform);
//                     pos, chunk_idx, hit := wb.raycast_into_terrain(terrain.wb_terrain, terrain_transform.position, mouse_world, mouse_direction);
                    
//                     if !hit do continue;
                    
//                     target_position = pos;
//                     player_path = physics.smooth_a_star(transform.position, target_position, 0.5);
//                     path_idx = 1;
//                     net.send_new_player_position(target_position, net_id.network_id);
//                     break;
//                 }
//             }
//         }
//         if      plat.get_input(configs.key_config.spell_1) do cast_spell(caster, 1);
//         else if plat.get_input(configs.key_config.spell_2) do cast_spell(caster, 2);
//         else if plat.get_input(configs.key_config.spell_3) do cast_spell(caster, 3);
//         else if plat.get_input(configs.key_config.spell_4) do cast_spell(caster, 4);
//         else if plat.get_input(configs.key_config.spell_5) do cast_spell(caster, 5);
//     }

//     if math.magnitude(Vec3{final_pos.x, transform.position.y, final_pos.z} - transform.position) > 0.1 {
//         p := final_pos;
//         if path_idx < len(player_path)-1 {
//             p = player_path[path_idx];
//             if math.magnitude(Vec3{p.x, transform.position.y, p.z} - transform.position) < 0.01 {
//                 path_idx += 1;
//             }
//         }
//         height := get_terrain_height_at_position(transform.position + Vec3{0,2,0});
//         p1 := move_towards({transform.position.x, 0, transform.position.z}, {p.x,0,p.z}, base_move_speed * dt);
//         transform.position = {p1.x, height, p1.z};
//         transform.rotation = math.euler_angles(0, look_y_rot(transform.position, p) - math.PI / 2, 0);

//         animator.controller.player.current_animation = "enter";
//     } else {
//         animator.controller.player.current_animation = "idle";
//     }
// }

// attack :: proc(using player: ^Player_Entity, target: Enemy) {

// }

// move_towards :: proc(current, target: math.Vec3, maxDelta: f32) -> math.Vec3 {
//     a := target - current;
//     mag := math.magnitude(a);
//     if (mag <= maxDelta || mag == 0) {
//         return target;
//     }

//     return current + a / mag * maxDelta;
// }

// look_y_rot :: proc(current, target: math.Vec3) -> f32 {
//     dir := target - current;
//     return f32(math.atan2(f64(dir.z), f64(-dir.x)));
// }