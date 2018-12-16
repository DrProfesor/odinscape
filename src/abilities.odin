package main

using import "core:fmt"
using import "core:math"

import wb "shared:workbench"

Ability_Definition :: struct {
	name: string,
	icon: wb.Sprite, // todo(josh): set this up
	target_type: Ability_Target,
	range: f32,
	on_activate: proc(ability: ^Ability_Definition, user: ^Unit_Component, target_unit: ^Unit_Component, cursor_position_on_terrain: Vec3),
}

Ability_Target :: enum i32 {
	Click,    // self or cursor location
	Friendly, // caster + units on their team
	Allies,   // units on the caster's team
	Enemy,    // units not on the casters team
}

Ability_Manager :: struct {
	all_ability_definitions: map[string]^Ability_Definition,

	show_ability_editor: bool,
}

ability_manager: Ability_Manager;

init_abilities :: proc() {
	using ability_manager;

	// todo(josh): Pull from config file for abilities
	all_ability_definitions["slash"] = new_clone(Ability_Definition{
		"Slash",
		{}, // todo(josh): do this
		Ability_Target.Enemy,
		5,
		damage_ability
	});
}

get_ability :: proc(id: string) -> (^Ability_Definition, bool) {
	a, ok := ability_manager.all_ability_definitions[id];
	return a, ok;
}

damage_ability :: proc(ability: ^Ability_Definition, user: ^Unit_Component, target: ^Unit_Component, cursor_position_on_terrain: Vec3) {
	assert(user != nil);
	logln("ABILITY!!!");
	if target != nil {
		health := get_component(target.entity, Health_Component);
		assert(health != nil);
		take_damage(health, 1);
	}
}

projectile_ability :: proc(ability: ^Ability_Definition, user: ^Unit_Component, target: ^Unit_Component, cursor_position_on_terrain: Vec3) {

}