package shared

import "shared:wb/ecs"
import "shared:wb/math"

Player_Entity :: struct {
    using base: ecs.Component_Base,
    is_local : bool,
    
    base_move_speed: f32 "replicate:server",

    target_position: math.Vec3,

    player_path: []math.Vec3,
	path_idx: int,
}