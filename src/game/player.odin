package game

using import "core:fmt"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/types"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

import wb_plat  "shared:workbench/platform"
import wb_math  "shared:workbench/math"
import wb       "shared:workbench"

using import "../configs"
using import "../physics"
using import "../net"
using import "../shared"

target_position : Vec3;
local_player : Entity;

player_init :: proc(using player: ^Player_Entity) {
    when DEVELOPER {
        is_local = true;
    } else {
        net_id, ok := get_component(e, Network_Id);
        is_local = net_id.controlling_client == net.client_id;
        logln("PlayerInit:", net_id.controlling_client, net.client_id);
    }
    
    if is_local {
        local_player = e;
        
        transform, texists := get_component(e, Transform);
        target_position = transform.position;
    }
    
    model := add_component(e, Model_Renderer);
    
    model.model_id = configs.player_config.model_id;
    model.texture_id = configs.player_config.texture_id;
    
    model.scale = Vec3{1, 1, 1};
	model.color = Colorf{1, 1, 1, 1};
	model.shader_id = "skinning";
	model.material = wb.Material {
        {1, 0.5, 0.3, 1}, {1, 0.5, 0.3, 1}, {0.5, 0.5, 0.5, 1}, 32
    };
    
    animator := add_component(e, Animator);
    animator.current_animation = "idle";
    
    // TODO saving
    stats := add_component(e, Stats);
    append(&stats.stats, Stat{ "melee_attack", 0, 1 });
    append(&stats.stats, Stat{ "health", 0, 1 });
    append(&stats.stats, Stat{ "magic", 0, 1 });
    append(&stats.stats, Stat{ "ranged_attack", 0, 1 });
    append(&stats.stats, Stat{ "speed", 0, 1 });
    
    health := add_component(e, Health);
}

player_update :: proc(using player: ^Player_Entity, dt: f32) {
    
    if editor_config.enabled do return;
    
    // TODO networked players
    if e != local_player do return;
    
    transform, _ := get_component(e, Transform);
    animator,  _ := get_component(e, Animator);
    
    if wb_plat.get_input_down(key_config.move_to) {
        mouse_world := wb.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
        
        hits := make([dynamic]RaycastHit, 0, 10);
        hit := raycast(wb.wb_camera.position, mouse_direction * 100, &hits);
        
        if hit > 0 {
            first_hit := hits[0];
            target_position = first_hit.intersection_start;
        }
    }
    
    dist := target_position - transform.position;
    mag := magnitude(dist);
    
    if mag > 0.01 {
        
        points := a_star(transform.position + Vec3{0, 0.2, 0}, target_position + Vec3{0, 0.2, 0});
        p := target_position;
        if len(points) >= 2 {
            p = points[len(points) - 2];
        }
        
        transform.position = move_towards(transform.position, p, 1 * dt);
        
        transform.position = Vec3{transform.position.x, target_position.y, transform.position.z};
        transform.rotation = euler_angles(0, look_y_rot(transform.position, p) - PI / 2, 0);
        
        
        for point, i in points {
            if i == 1 do wb.draw_debug_box(point, Vec3{0.12,0.12,0.12}, Colorf{0.25, 0.1, 0.7, 1});
            wb.draw_debug_box(point, Vec3{0.2,0.2,0.2}, COLOR_BLUE);
        }
        
        
        animator.current_animation = "enter";
    } else {
        animator.current_animation = "idle";
    }
}

player_end :: proc() {
}

move_towards :: proc(current, target: Vec3, maxDelta: f32) -> Vec3 {
    a := target - current;
    mag := magnitude(a);
    if (mag <= maxDelta || mag == 0) {
        return target;
    }
    
    return current + a / mag * maxDelta;
}

look_y_rot :: proc(current, target: Vec3) -> f32 {
    dir := target - current;
    return f32(atan2(f64(dir.z), f64(-dir.x)));
}