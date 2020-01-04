package shared

import "shared:workbench/ecs"

Player_Entity :: struct {
    using base: ecs.Component_Base,
    is_local : bool,
}