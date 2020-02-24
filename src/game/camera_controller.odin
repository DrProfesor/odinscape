package game

import "core:fmt"

import "shared:workbench/types"
import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/ecs"
import "shared:workbench/math"

import wb    "shared:workbench"

import "../configs"

init_camera :: proc() {

}

update_camera :: proc(dt: f32) {
    target_transform, exists := ecs.get_component(local_player, ecs.Transform);

    if !exists do return;

    wb.main_camera.position = target_transform.position + math.Vec3{0, 5, 5};
    // wb.main_camera.rotation = wb.rotate_quat_by_degrees(math.Quat{0,0,0,1}, math.Vec3{-45, 0, 0});
}