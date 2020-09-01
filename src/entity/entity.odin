package entity

import wb "shared:wb"
import "shared:wb/math"
import "shared:wb/types"
import "shared:wb/gpu"

import "../shared"
import "../save"

all_entities: [2048]Entity;
player_characters: [dynamic]^Player_Character;
enemies: [dynamic]^Enemy;

Entity :: struct {
	kind: union {
		Player_Character,
		Enemy,
	}

	id: int,
	network_id: int, // -1 for non networked

	position: math.Vec3,
	rotation: math.Quat,
	scale   : math.Vec3,
}

Player_Character :: struct {
	is_local : bool,

	// configuration
	base_move_speed: f32 "replicate:server",

	selected_character: ^save.Character_Save,

	// runtime movement data
	target_position: math.Vec3,
	player_path: []math.Vec3,
	path_idx: int,

	using model: Model_Renderer,
	using anim: Animator,

	using stat_holder: Stat_Holder,
	using combatant: Combatant,
	using caster: Ability_Caster,
}

Enemy :: struct {
	target_position: math.Vec3 "replicate:server",
    
    path: []math.Vec3,
	path_idx: int,

	target_network_id: int "replicate:server",

	base_move_speed: f32 "replicate:server", 
	target_distance_from_target: f32 "replicate:server",
	detection_radius: f32 "replicate:server",
	cutoff_radius: f32 "replicate:server",

	using model: Model_Renderer,
	using anim: Animator,

	using stat_holder: Stat_Holder,
	using combatant: Combatant,
	using caster: Ability_Caster,
}

Stat_Holder :: struct {
	stats : map[string]Stat
}

Stat :: struct {
    id: string,
    experience : f32,
    level : int,
}

Combatant :: struct {
	current_health: f32,
}

Ability_Caster :: struct {
	global_cooldown: f64 "replicate:server",
    last_cast_time: f64 "replicate:server",

    spellbook: Spellbook "replicate:server",

    target_entity: int "replicate:server",
}

Spell :: shared.Spell;
Spell_Type :: shared.Spell_Type;
Spell_Config_Data :: shared.Spell_Config_Data;
Spellbook :: struct {
	spells: [dynamic]Spell,
	assigned_spells: []int, // will be the size of spells + 1 for basic attack. Indexes into spells
}

Model_Renderer :: struct {
	model_id: string,
    texture_id: string,
    shader_id: string,
    color: types.Colorf,
    material: wb.Material,
    scale: math.Vec3,
}

Animator :: struct {
	controller: wb.Animation_Controller,
    previous_mesh_id: string,
    open_animator_window: bool,
}