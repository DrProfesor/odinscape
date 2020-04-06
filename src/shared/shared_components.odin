package shared

import "shared:workbench/ecs"
import "shared:workbench/math"

Player_Entity :: struct {
    using base: ecs.Component_Base,
    is_local : bool,
    target_position: math.Vec3,
    player_path: []math.Vec3,
	path_idx: int,
}