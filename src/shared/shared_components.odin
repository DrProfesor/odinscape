package shared

using import "shared:workbench/ecs"

Player_Entity :: struct {
    using base: Component_Base,
    is_local : bool,
}