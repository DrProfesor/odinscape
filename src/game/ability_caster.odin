package game

import "shared:wb/ecs"

import plat "shared:wb/platform"

import "../configs"

Ability_Caster :: struct {
    using base: ecs.Component_Base,

    global_cooldown: f32,
    last_cast_time: f32,

    spellbook: Spellbook,
}

init_ability_caster :: proc(using caster: ^Ability_Caster) {

}

update_ability_caster :: proc(using caster: ^Ability_Caster, dt: f32) {
	if local_player != e do return;

	if plat.get_input(configs.key_config.spell_1) {
		cast_spell(caster, caster.spellbook[1]);
	} else if plat.get_input(configs.key_config.spell_2) {
		cast_spell(caster, caster.spellbook[2]);
	} else if plat.get_input(configs.key_config.spell_3) {
		cast_spell(caster, caster.spellbook[3]);
	} else if plat.get_input(configs.key_config.spell_4) {
		cast_spell(caster, caster.spellbook[4]);
	} else if plat.get_input(configs.key_config.spell_5) {
		cast_spell(caster, caster.spellbook[5]);
	} else {
		cast_spell(caster, caster.spellbook[0]);
	}
}

cast_spell :: proc(using caster: ^Ability_Caster, spell: Spell) {

}

Spellbook :: struct {
	spells: [dynamic]Spell,
	assigned_spells: []Spell, // will be the size of spells + 1 for basic attack
}

// TODO(jake): should spell types be a union?
// It would be nice to be able to define all spells through config, so maybe no?
Spell :: struct {
	type: Spell_Type,

	cooldown: f32,
	base_damage: f32,
	range: f32,

	unlock_level: int,
	is_owned: bool,

	respects_global_cooldown: bool,
}

Spell_Type :: enum {
	Basic_Attack,
}