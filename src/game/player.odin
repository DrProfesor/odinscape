package game

using import "core:math"
using import "core:fmt"

using import    "shared:workbench/basic"
using import    "shared:workbench/logging"
using import "shared:workbench/ecs"

import wb_plat "shared:workbench/platform"
import wb_gpu  "shared:workbench/gpu"
import wb_math  "shared:workbench/math"
import wb      "shared:workbench"

using import "../configs"
using import "../physics"
using import "../net"
using import "../shared"

target_position : Vec3;
local_player : Entity;

player_init :: proc(using player: ^Player_Entity) {
    net_id,ok := get_component(e, Network_Id);
    is_local = net_id.controlling_client == net.client_id;
    
    logln("PlayerInit:", net_id.controlling_client, net.client_id);
    
    if is_local do local_player = e;
}

player_update :: proc(dt: f32) {
    
    if wb_plat.get_input(key_config.move_to) {
        mouse_world := wb_gpu.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb_gpu.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
        
        hits := make([dynamic]RaycastHit, 0, 10);
        hit := raycast(wb.wb_camera.position, mouse_direction * 100, &hits);
        
        if hit > 0 {
            first_hit := hits[0];
            
            move_point := first_hit.intersection_start;
        }
    }
}

player_end :: proc() {
    
}