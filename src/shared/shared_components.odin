package shared

import "shared:wb/ecs"
import "shared:wb/math"

Player_Entity :: struct {
    using base: ecs.Component_Base,
    is_local : bool,
    
    // configuration
    base_move_speed: f32 "replicate:server",

    // runtime movement data
    target_position: math.Vec3,
    player_path: []math.Vec3,
	path_idx: int,
}

// TODO(jake): spell types may need to be a union if a spell kind has weird data
// It would be nice to be able to define all spells through config though
Spell :: struct {

    // config data
    using config: Spell_Config_Data

    // savedata
    is_owned: bool,

    // runtime
    last_cast: f64,
}

Spell_Type :: enum {
    Basic_Attack,
}

Spell_Config_Data :: struct {
    type: Spell_Type,
    cooldown: f64,
    base_damage: f32,
    range: f32,
    must_face: bool,
    unlock_level: int,
    respects_global_cooldown: bool,

    extra_data: union {
        Unused,
        AOE_Spell,
    }
}

Unused :: struct {}

AOE_Spell :: struct {
    aoe_range: f32,
}