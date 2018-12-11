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
	Self,
	Unit,
	Location,
}

all_ability_definitions: map[string]^Ability_Definition;

init_abilities :: proc() {
	// todo(josh): Pull from config file for abilities
	all_ability_definitions["slash"] = new_clone(Ability_Definition{
		"Slash",
		{}, // todo(josh): do this
		Ability_Target.Unit,
		5,
		damage_ability
	});
}

get_ability :: proc(id: string) -> (^Ability_Definition, bool) {
	a, ok := all_ability_definitions[id];
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
