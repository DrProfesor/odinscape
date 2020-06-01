package game

import "shared:wb/ecs"

import plat "shared:wb/platform"

import "../configs"

Ability_Caster :: struct {
    using base: ecs.Component_Base,

    global_cooldown: f32 "replicate:server",
    last_cast_time: f32 "replicate:server",

    spellbook: Spellbook "replicate:server",

    target_entity: ecs.Entity "replicate:server",
}

init_ability_caster :: proc(using caster: ^Ability_Caster) {

}

update_ability_caster :: proc(using caster: ^Ability_Caster, dt: f32) {
	if local_player != e do return;

	if target_entity == -1 do return;

	num_spells := len(caster.spellbook.assigned_spells);
	if      plat.get_input(configs.key_config.spell_1) && num_spells > 1 do cast_spell(caster, &caster.spellbook.assigned_spells[1]);
	else if plat.get_input(configs.key_config.spell_2) && num_spells > 2 do cast_spell(caster, &caster.spellbook.assigned_spells[2]);
	else if plat.get_input(configs.key_config.spell_3) && num_spells > 3 do cast_spell(caster, &caster.spellbook.assigned_spells[3]);
	else if plat.get_input(configs.key_config.spell_4) && num_spells > 4 do cast_spell(caster, &caster.spellbook.assigned_spells[4]);
	else if plat.get_input(configs.key_config.spell_5) && num_spells > 5 do cast_spell(caster, &caster.spellbook.assigned_spells[5]);
	else do /*no length check here. they will always have basic attack*/	cast_spell(caster, &caster.spellbook.assigned_spells[0]);
}

cast_spell :: proc(using caster: ^Ability_Caster, spell: ^Spell) {
	target_transform, _ := ecs.get_component(target_entity, Transform);
	target_health, has_health := ecs.get_component(target_entity, Health);

	transform, _ := ecs.get_component(e, Transform);


}

Spellbook :: struct {
	spells: [dynamic]Spell,
	assigned_spells: []Spell, // will be the size of spells + 1 for basic attack
}

// TODO(jake): spell types may need to be a union if a spell kind has weird data
// It would be nice to be able to define all spells through config, so maybe no?
Spell :: struct {
	type: Spell_Type,

	cooldown: f32,
	base_damage: f32,
	range: f32,
	must_face: bool,

	unlock_level: int,
	is_owned: bool,

	respects_global_cooldown: bool,

	// runtime
	last_cast: f32,
}

Spell_Type :: enum {
	Basic_Attack,
}