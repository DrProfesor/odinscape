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

    wb.main_camera.position = target_transform.position + math.Vec3{0, 10, 5};
    wb.main_camera.rotation = math.degrees_to_quaternion({-60, 0, 0});//math.direction_to_quaternion(math.norm(target_transform.position - wb.main_camera.position));
}