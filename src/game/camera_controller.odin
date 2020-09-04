package game

import "core:fmt"

import "shared:wb/types"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/ecs"
import "shared:wb/math"

import wb    "shared:wb"

import "../configs"
import "../entity"

init_camera :: proc() {

}

update_camera :: proc(dt: f32) {
    // if local_player == nil do return;

    // player_entity := cast(^entity.Entity)local_player;

    // wb.main_camera.position = player_entity.position + math.Vec3{0, 10, 5};
    // wb.main_camera.rotation = math.degrees_to_quaternion({-60, 0, 0});//math.direction_to_quaternion(math.norm(target_transform.position - wb.main_camera.position));
}