package game

import "core:fmt"

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"

Stats :: struct {
    using base: ecs.Component_Base,
    stats : map[string]Stat "wbml_noserialize",
}

Stat :: struct {
    id: string,
    experience : f32,
    level : int,
}

init_stat_component :: proc(using health: ^Stats) {
    stats["melee_attack"] = Stat{ "melee_attack", 0, 1 };
    stats["health"] = Stat{ "health", 0, 1 };
    stats["magic"] = Stat{ "magic", 0, 1 };
    stats["ranged_attack"] = Stat{ "ranged_attack", 0, 1 };
    stats["speed"] = Stat{ "speed", 0, 1 };
}

get_experience_required :: proc(level: int) -> f32 {
    experience : f32 = 0;

    for x in 1..level-1 {
        experience += f32(x) + 300 * math.pow(2, f32(x) / f32(7));
    }
    experience /= 4;

    return experience;
}

get_stat :: proc(entity: ecs.Entity, stat_id: string) -> Stat {
    stat_comp, ok := ecs.get_component(entity, Stats);
    assert(ok);

    assert(stat_id in stat_comp.stats, fmt.tprint("No stat with that name ", stat_id, " on entity: ", entity));

    return stat_comp.stats[stat_id];
}

add_experience :: proc(entity: ecs.Entity, stat_id: string, amount: f32) {
    stat_comp, ok := ecs.get_component(entity, Stats);
    assert(ok);
    assert(stat_id in stat_comp.stats, fmt.tprint("No stat with that name ", stat_id, " on entity: ", entity));

    stat := stat_comp.stats[stat_id];
    defer stat_comp.stats[stat_id] = stat;

    stat.experience += amount;

    required := get_experience_required(stat.level + 1);
    if stat.experience >= required {
        stat.experience -= required;
        stat.level += 1;
    }
}