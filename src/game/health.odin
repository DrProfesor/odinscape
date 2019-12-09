package game

using import "core:fmt"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/types"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

Health :: struct {
    using base: Component_Base,
    amount: f32,
}

init_health :: proc(using health: ^Health) {
    health_stat := get_stat(e, "health");
    amount = f32(health_stat.level * 10);
}

take_damage :: proc(entity: Entity, amount: f32) {
    health_comp, ok := get_component(entity, Health);
    assert(ok);
    
    health_comp.amount -= amount;
    
    if health_comp.amount <= 0 {
        // Kill entity
    }
}

restore_health :: proc(entity: Entity, amount: f32) {
    health_comp, ok := get_component(entity, Health);
    assert(ok);
    
    health_stat := get_stat(entity, "health");
    
    // TODO this is going to change
    max_health := f32(health_stat.level * 10);
    
    health_comp.amount += amount;
    if health_comp.amount > max_health {
        health_comp.amount = max_health;
    }
}