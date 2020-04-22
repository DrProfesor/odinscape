package game

import "core:fmt"

import "shared:workbench/basic"
import log "shared:workbench/logging"
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

local_player: ecs.Entity;

player_init :: proc(using player: ^shared.Player_Entity) {
    when SERVER {
        transform, texists := ecs.get_component(e, ecs.Transform);
        target_position = transform.position;

        logln("Initting player");

        model := net.network_add_component(e, Model_Renderer);
        animator := net.network_add_component(e, Animator);
        stats := net.network_add_component(e, Stats);
        health := net.network_add_component(e, Health);

        player.base_move_speed = 3;
    } else {
        net_id, _ := ecs.get_component(e, net.Network_Id);
        is_local = net_id.controlling_client == net.client_id;
        if is_local {
            local_player = e;
        }

        base_move_speed = 3;

        model, mok := ecs.get_component(e, Model_Renderer);
        assert(mok);
        model.model_id = configs.player_config.model_id;
        model.texture_id = configs.player_config.texture_id;
        model.scale = math.Vec3{1, 1, 1};
        model.color = types.Colorf{1, 1, 1, 1};
        model.shader_id = "skinning";
        model.material = wb.Material {
            0.5,0.5,0.5
        };

        animator, aok := ecs.get_component(e, Animator);
        assert(aok);
        animator.current_animation = "idle";
    }
}

player_update :: proc(using player: ^shared.Player_Entity, dt: f32) {

    if wb.debug_window_open do return;
    
    transform, _ := ecs.get_component(e, ecs.Transform);
    animator,  _ := ecs.get_component(e, Animator);
    net_id,    _ := ecs.get_component(e, net.Network_Id);

    if wb_plat.get_input(configs.key_config.move_to) && is_local {
        mouse_world := wb.get_mouse_world_position(wb.main_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb.get_mouse_direction_from_camera(wb.main_camera, wb_plat.mouse_unit_position);
        terrains := ecs.get_component_storage(Terrain);
        for terrain in terrains {
            terrain_transform, ok := ecs.get_component(terrain.e, ecs.Transform);
            pos, hit := wb.raycast_into_terrain(terrain.wb_terrain, terrain_transform.position, mouse_world, mouse_direction);
            if hit {
                target_position = pos;
                // TODO(jake): Speed this up like crazy
                player_path = physics.smooth_a_star(transform.position, target_position, 0.5);
                path_idx = 1;
                net.send_new_player_position(target_position, net_id.network_id);
                break;
            }
        }
    }

    dist := target_position - transform.position;
    mag := math.magnitude(dist);

    // collision grid debug
    // for x in -15..15 {
    //     for z in -15..15 {
    //         pos := transform.position + math.Vec3{ f32(x), 0, f32(z) };
    //         hit := physics.overlap_point(pos) > 0;
    //         wb.draw_debug_box(pos, math.Vec3{0.9,0.9,0.9}, hit ? types.COLOR_RED : types.COLOR_BLUE);
    //     }
    // }

    if mag > 0.1 {
        p := target_position;
        if path_idx < len(player_path)-1 {
            p = player_path[path_idx];
            if math.distance(math.Vec3{p.x, 0, p.z}, math.Vec3{transform.position.x, 0, transform.position.z}) < 0.01 {
                path_idx += 1;
            }
        }

        height := get_terrain_height_at_position({transform.position.x, transform.position.z});
        p1 := move_towards(transform.position, p, base_move_speed * dt);
        transform.position = {p1.x, height, p1.z};
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