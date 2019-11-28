package game

using import "core:fmt"

using import "shared:workbench/types"
using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

import wb    "shared:workbench"

using import "../configs"

init_camera :: proc() {
    
}

update_camera :: proc(dt: f32) {
    target_transform, exists := get_component(local_player, Transform);
    
    if !exists do return;
    
    wb.wb_camera.position = target_transform.position + Vec3{0, 5, 5};
    wb.wb_camera.rotation = wb.rotate_quat_by_degrees(Quat{0,0,0,1}, Vec3{-45, 0, 0});
}