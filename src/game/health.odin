package game

import "core:fmt"

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"

Health :: struct {
    using base: ecs.Component_Base,
    amount: f32,
}

init_health :: proc(using health: ^Health) {
    health_stat := get_stat(e, "health");
    amount = f32(health_stat.level * 10);
}

take_damage :: proc(entity: ecs.Entity, amount: f32) {
    health_comp, ok := ecs.get_component(entity, Health);
    assert(ok);

    health_comp.amount -= amount;

    if health_comp.amount <= 0 {
        // Kill entity
    }
}

restore_health :: proc(entity: ecs.Entity, amount: f32) {
    health_comp, ok := ecs.get_component(entity, Health);
    assert(ok);

    health_stat := get_stat(entity, "health");

    // TODO this is going to change
    max_health := f32(health_stat.level * 10);

    health_comp.amount += amount;
    if health_comp.amount > max_health {
        health_comp.amount = max_health;
    }
}