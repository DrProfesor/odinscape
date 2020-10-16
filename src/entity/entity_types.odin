package entity

import "shared:wb"
import "shared:wb/basic"
import log "shared:wb/logging"

import "../util"
import "../shared"
import "../save"
import "../configs"

/////////////////////////////////////////////
//   		  Entity Components            //
/////////////////////////////////////////////

// Stats
Stat_Holder :: struct {
	stats : map[string]Stat
}

Stat :: struct {
    experience : f32,
    level : int,
}


// Combatants
Combatant :: struct {
	current_health: f32,
}


// Spells
all_spell_configs: map[string]^Spell_Config_Data;
on_config_load :: proc() {
	temp := configs.get_all_config_values("Spells", Spell_Config_Data);
	defer delete(temp);

	for k, v in temp {
		if k in all_spell_configs {
			all_spell_configs[k]^ = v;
		} else {
			all_spell_configs[k] = new_clone(v);
		}
	}
}

Spell_Caster :: struct {
	global_cooldown: f64 "replicate:server",
    last_cast_time: f64 "replicate:server",

    spellbook: Spellbook "replicate:server",

    target_entity: int "replicate:server",
}

// Contains all the spells players own. And which ones have been prepared to cast.
Spellbook :: struct {
	spells: [dynamic]Spell,
	assigned_spells: []int, // will be the size of spells + 1 for basic attack. Indexes into spells
}

// TODO(jake): spell types may need to be a union if a spell kind has weird data
// It would be nice to be able to define all spells through config though
Spell :: struct {

    // config data
    using config: ^Spell_Config_Data

    // savedata / runtime
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


// Renderers
Model_Renderer :: struct {
	model_id: string,
    texture_id: string,
    shader_id: string,
    material_id: string,
    tint: wb.Vector4,
}

Animator :: struct {
	// controller: wb.Animation_Controller,
    previous_mesh_id: string,
    open_animator_window: bool,
}









/////////////////////////////////////////////
//   		       Entities                //
/////////////////////////////////////////////

@entity
Player_Character :: struct {
	is_local : bool,

	// configuration
	base_move_speed: f32 "replicate:server",

	selected_character: ^save.Character_Save,

	// runtime movement data
	target_position: wb.Vector3,
	path: []wb.Vector3,
	path_idx: int,

	using model: Model_Renderer,
	using animator: Animator,

	using stat_holder: Stat_Holder,
	using combatant: Combatant,
	using caster: Spell_Caster,
}

create_player :: proc(character: ^save.Character_Save, is_local: bool) -> ^Player_Character{
	player := create_entity({0,0,0}, wb.Quaternion(1), {1,1,1});

	player.name = character.character_name;

	pc := Player_Character {};
	pc.is_local = is_local;
	pc.selected_character = character;

	pc.base_move_speed = 2;

	// Model
	// TODO more advanced character loading
	pc.model.model_id = character.model_id;
	pc.model.texture_id = character.texture_id;
	pc.model.shader_id = "simple_rgba";
    pc.model.material_id = "player_material";
    // pc.model.color = core.Colorf{1, 1, 1, 1};

	// Animator
	// model, ok := wb.try_get_model(pc.model.model_id);
 	// wb.init_animation_player(&pc.animator.controller.player, model);

	// Stats
	for stat in character.stats {
		pc.stat_holder.stats[stat.id] = { stat.experience, stat.level };
	}

	// Combat Data
	pc.combatant.current_health = character.current_health;

	// Spells
	pc.caster.global_cooldown = 1;
	pc.caster.last_cast_time = 0;
	pc.caster.target_entity = -1;
	if character.assigneable_slots == 0 do character.assigneable_slots = 1;
	pc.caster.spellbook.assigned_spells = make([]int, character.assigneable_slots+1);

	j := 0;
	for s, i in character.unlocked_spells {
		spell := Spell {
			all_spell_configs[s.id],
			s.last_cast,
		};

		append(&pc.caster.spellbook.spells, spell);
		if s.is_assigned {
			pc.caster.spellbook.assigned_spells[j+1] = i;
		}
	}

	player.kind = pc;
	append(&all_Player_Character, cast(^Player_Character) player);

	log.logln("Create player");

	return cast(^Player_Character) player;
}



@entity
Enemy :: struct {
	target_position: wb.Vector3 "replicate:server",
    
    path: []wb.Vector3,
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
	using caster: Spell_Caster,
}



@entity
Simple_Model :: struct {
	using model: Model_Renderer,
}