package game

import "shared:workbench/ecs"
import "shared:workbench/math"

init_enemy :: proc(using enemy: ^Enemy) {

}

update_enemy :: proc(using enemy: ^Enemy, dt: f32) {

}

Enemy :: struct {
    using base: ecs.Component_Base,
    target_position: math.Vec3,
    player_path: []math.Vec3,
	path_idx: int,
}