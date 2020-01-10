package game

import "core:fmt"

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"

import wb_plat  "shared:workbench/platform"
import wb_math  "shared:workbench/math"
import wb       "shared:workbench"

import "../configs"
import "../physics"
import "../net"
import "../shared"

target_position : math.Vec3;
local_player : ecs.Entity;

player_init :: proc(using player: ^shared.Player_Entity) {
    when DEVELOPER {
        is_local = true;
    } else {
        net_id, ok := get_component(e, Network_Id);
        is_local = net_id.controlling_client == net.client_id;
        logln("PlayerInit:", net_id.controlling_client, net.client_id);
    }
    
    if is_local {
        local_player = e;
        
        transform, texists := ecs.get_component(e, ecs.Transform);
        target_position = transform.position;
    }
    
    model := ecs.add_component(e, Model_Renderer);
    
    model.model_id = configs.player_config.model_id;
    model.texture_id = configs.player_config.texture_id;
    
    model.scale = math.Vec3{1, 1, 1};
	model.color = types.Colorf{1, 1, 1, 1};
	model.shader_id = "skinning";
	model.material = wb.Material {
        {1, 0.5, 0.3, 1}, {1, 0.5, 0.3, 1}, {0.5, 0.5, 0.5, 1}, 32
    };
    
    animator := ecs.add_component(e, Animator);
    animator.current_animation = "idle";
    
    // TODO saving
    stats := ecs.add_component(e, Stats);
    append(&stats.stats, Stat{ "melee_attack", 0, 1 });
    append(&stats.stats, Stat{ "health", 0, 1 });
    append(&stats.stats, Stat{ "magic", 0, 1 });
    append(&stats.stats, Stat{ "ranged_attack", 0, 1 });
    append(&stats.stats, Stat{ "speed", 0, 1 });
    
    health := ecs.add_component(e, Health);
}

player_path : []math.Vec3;
path_idx := 0;

player_update :: proc(using player: ^shared.Player_Entity, dt: f32) {
    
    if wb.debug_window_open do return;
    
    // TODO networked players
    if e != local_player do return;
    
    transform, _ := ecs.get_component(e, ecs.Transform);
    animator,  _ := ecs.get_component(e, Animator);
    
    if wb_plat.get_input_down(configs.key_config.move_to) {
        mouse_world := wb.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
        
        hits := make([dynamic]physics.RaycastHit, 0, 10);
        hit := physics.raycast(wb.wb_camera.position, mouse_direction * 100, &hits);
        
        if hit > 0 {
            first_hit := hits[0];
            target_position = first_hit.intersection_start;
            
            transform.position = math.Vec3{transform.position.x, target_position.y, transform.position.z};
            player_path = physics.a_star(transform.position + math.Vec3{0,0.2,0}, target_position + math.Vec3{0, 0.2, 0}, 0.25);
            path_idx = len(player_path) - 2; // start on the second last point
        }
    }
    
    dist := target_position - transform.position;
    mag := math.magnitude(dist);
    
    if mag > 0.01 {
        p := target_position;
        if path_idx > 0 {
            p = player_path[path_idx] - math.Vec3{0,0.2,0};
            
            for point in player_path {
                wb.draw_debug_box(point, math.Vec3{0.2,0.2,0.2}, types.COLOR_BLUE);
            }
            
            if math.distance(p, transform.position) < 0.00001 {
                path_idx -= 1;
            }
        }
        
        transform.position = move_towards(transform.position, p, 2 * dt);
        transform.rotation = math.euler_angles(0, look_y_rot(transform.position, p) - math.PI / 2, 0);
        
        animator.current_animation = "enter";
    } else {
        animator.current_animation = "idle";
    }
}

player_end :: proc() {
}

move_towards :: proc(current, target: math.Vec3, maxDelta: f32) -> math.Vec3 {
    a := target - current;
    mag := math.magnitude(a);
    if (mag <= maxDelta || mag == 0) {
        return target;
    }
    
    return current + a / mag * maxDelta;
}

look_y_rot :: proc(current, target: math.Vec3) -> f32 {
    dir := target - current;
    return f32(math.atan2(f64(dir.z), f64(-dir.x)));
}