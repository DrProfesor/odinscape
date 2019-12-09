package game

using import "core:fmt"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/types"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

Stats :: struct {
    using base: Component_Base,
    stats : [dynamic]Stat,
}

Stat :: struct {
    id: string,
    experience : f32,
    level : int,
}

get_experience_required :: proc(level: int) -> f32 {
    experience : f32 = 0;
    
    for x in 1..level-1 {
        experience += f32(x) + 300 * pow(2, f32(x) / f32(7));
    }
    experience /= 4;
    
    return experience;
}

get_stat :: proc(entity: Entity, stat_id: string) -> Stat {
    stat_comp, ok := get_component(entity, Stats);
    assert(ok);
    
    for stat in stat_comp.stats {
        if stat.id == stat_id do return stat;
    }
    
    assert(false, tprint("No stat with that name ", stat_id, " on entity: ", entity));
    return Stat{};
}

add_experience :: proc(entity: Entity, stat_id: string, amount: f32) {
    stat_comp, ok := get_component(entity, Stats);
    assert(ok);
    
    for i := 0; i < len(stat_comp.stats); i += 1 {
        stat := stat_comp.stats[i];
        
        if stat.id != stat_id do continue;
        
        stat.experience += amount;
        
        required := get_experience_required(stat.level + 1);
        if stat.experience >= required {
            stat.experience -= required;
            stat.level += 1;
        }
        
        stat_comp.stats[i] = stat;
        
        return; // success
    }
    
    assert(false, tprint("No stat with that name ", stat_id, " on entity: ", entity));
}