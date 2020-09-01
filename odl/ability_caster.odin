package game

import "core:time"

import "shared:wb/ecs"
import plat "shared:wb/platform"
import math "shared:wb/math"

import "../configs"
import "../shared"

all_spell_configs: []Spell_Config_Data;

abilities_on_config_load :: proc() {
	delete(all_spell_configs);
	all_spell_configs = configs.get_all_config_values("Spells", Spell_Config_Data);
	logln(all_spell_configs);
}

// init_ability_caster :: proc(using caster: ^Ability_Caster) {

// 	for cfg in &all_spell_configs {
// 		append(&spellbook.spells, Spell{
// 			cfg, true, 0,
// 		});
// 	}

// 	global_cooldown = 1.5;

// 	spellbook.assigned_spells = make([]int, 6);
// 	spellbook.assigned_spells[0] = 0;
// }

// update_ability_caster :: proc(using caster: ^Ability_Caster, dt: f32) {
// 	if local_player != e do return;
// 	if target_entity <= 0 do return;

// 	cast_spell_idx(caster, 0);
// }

// target is nullable for non-targeted spells
// can_use_spell_on_target :: proc(using caster: ^Ability_Caster, spell: ^Spell, target_entity: int) -> bool {
// 	transform, _ := ecs.get_component(e, Transform);
	
// 	if !spell.is_owned do return false;
	
// 	if spell.respects_global_cooldown && f64(time.now()._nsec)/f64(time.Second) < last_cast_time + global_cooldown do return false;
// 	if f64(time.now()._nsec)/f64(time.Second) < spell.last_cast + spell.cooldown do return false;

// 	if target != nil {
// 		direction := target.position - transform.position;
// 		distance := math.magnitude(direction);

// 		if distance > spell.range do return false;

// 		target_direction := math.direction_to_quaternion(math.norm(direction));
// 		if spell.must_face && math.dot(target_direction, transform.rotation) <= 0 do return false;
// 	}

// 	return true;
// }

// cast_spell_spell :: proc(using caster: ^Ability_Caster, spell: ^Spell) {
// 	switch spell.type {
// 		case .Basic_Attack: {
// 			target_transform, _ := ecs.get_component(target_entity, Transform);
// 			if !can_use_spell_on_target(caster, spell, target_transform) do return;
// 			logln("actually attack");

// 			target_health, has_health := ecs.get_component(target_entity, Health);
// 			if !has_health do return;

// 			damage := spell.base_damage;
// 			// TODO process through stats, and buffs
// 			target_health.amount -= damage;

// 			spell.last_cast = f64(time.now()._nsec)/f64(time.Second);
// 			last_cast_time = f64(time.now()._nsec)/f64(time.Second);
// 		}
// 	}
// }

// cast_spell_idx :: proc(using caster: ^Ability_Caster, idx: int) {
// 	if len(caster.spellbook.assigned_spells) <= idx do return;

// 	spell_idx := caster.spellbook.assigned_spells[idx];
// 	cast_spell(caster, &caster.spellbook.spells[spell_idx]);
// }

// cast_spell :: proc{cast_spell_spell, cast_spell_idx};


