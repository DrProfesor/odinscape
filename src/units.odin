package main

using import    "core:fmt"
using import    "core:math"
	  import    "core:mem"

	  import wb "shared:workbench"
	  import ai "shared:workbench/external/assimp"
	  import coll "shared:workbench/collision"

// @Component
Unit_Component :: struct {
	using base: Component_Base,

	move_speed: f32,

	attack_damage: int,
	attack_range: f32,
	attack_cooldown: f32,
	attack_recovery: f32,

	cur_attack_cooldown: f32,

	using _unserialized : struct {
		// note(josh): pointer should always be to a unique field in `key_config`
		abilities: map[^Game_Input]string, // has to be a pointer to a Game_Input because of an odin bug with enum keys for maps

		command_blockers: [dynamic]Command_Blocker,
		queued_commands:  [dynamic]Unit_Command,
	}
}

ATTACK_RECOVERY_TIME :: 0.6;

unit_component :: proc(move_speed: f32, damage: int, range: f32, cooldown: f32) -> Unit_Component {
	unit: Unit_Component;
	unit.move_speed = move_speed;
	unit.attack_damage = damage;
	unit.attack_range = range;
	unit.attack_cooldown = cooldown;
	return unit;
}


init__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	abilities[&key_config.ability1] = "slash";
}


update__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	cur_attack_cooldown -= wb.fixed_delta_time;
	if cur_attack_cooldown < 0 do cur_attack_cooldown = 0;

	for i := len(command_blockers)-1; i >= 0; i -= 1 {
		blocker_base := &command_blockers[i];
		do_remove := false;

		#complete switch blocker in &blocker_base.kind {
			case Timed_Blocker: {
				blocker.time_left -= wb.fixed_delta_time;
				if blocker.time_left <= 0 do do_remove = true;
			}
		}

		if do_remove {
			unordered_remove(&command_blockers, i);
		}
	}

	if len(command_blockers) > 0 do return;

	if len(queued_commands) == 0 do return;

	base_command := &queued_commands[0];
	completed := false;

	#complete switch command in &base_command.kind {
		case Move_Command: {
			tf := get_component(entity, Transform);
			completed = do_move_command(tf, command.target, move_speed);
		}

		case Approach_Command: {
			tf := get_component(entity, Transform);
			other_tf := get_component(command.target, Transform);
			if other_tf == nil {
				completed = true;
				break;
			}
			completed = do_move_command(tf, other_tf.position, move_speed);
		}

		case Patrol_Command: {
			tf := get_component(entity, Transform);
			if command.go_to_1 {
				if do_move_command(tf, command.point1, move_speed) {
					command.go_to_1 = false;
				}
			}
			else {
				if do_move_command(tf, command.point2, move_speed) {
					command.go_to_1 = true;
				}
			}
		}

		case Ability_Command: {
			//
			tf := get_component(entity, Transform);
			assert(tf != nil);
			other_tf := get_component(command.target, Transform);
			if other_tf == nil {
				completed = true;
				break;
			}
			if !do_move_command(tf, other_tf.position, move_speed, attack_range) {
				// still approaching target
				break;
			}

			completed = true;

			//
			ability, ability_exists := get_ability(command.ability);
			if !ability_exists {
				logln("Error: Ability doesn't exist but was somehow queued up: ", command.ability);
				break;
			}

			// todo(josh): this is a lotta string compares
			has_ability: bool;
			for _, unit_ability in abilities {
				if unit_ability == command.ability {
					has_ability = true;
					break;
				}
			}
			if !has_ability {
				logln("Warning: Unit didn't have ability but it was queued up somehow: ", command.ability);
				break;
			}

			add_timed_blocker(unit, ATTACK_RECOVERY_TIME);

			other_unit := get_component(command.target, Unit_Component);
			assert(ability.on_activate != nil, ability.name);
			ability.on_activate(ability, unit, other_unit, command.cursor_position_on_terrain);
		}

		case Attack_Command: {
			tf := get_component(entity, Transform);
			assert(tf != nil);
			other_tf := get_component(command.target, Transform);
			if other_tf == nil {
				completed = true;
				break;
			}

			if !do_move_command(tf, other_tf.position, move_speed, attack_range) {
				// still approaching target
				break;
			}

			other_health := get_component(command.target, Health_Component);
			if other_health == nil || other_health.health <= 0 {
				completed = true;
				break;
			}

			if cur_attack_cooldown <= 0 {
				add_timed_blocker(unit, ATTACK_RECOVERY_TIME);

				take_damage(other_health, attack_damage);
				if other_health.health <= 0 {
					completed = true;
				}

				cur_attack_cooldown = attack_cooldown;
			}
		}
	}

	if alive(entity) { // throughout the process of attacking/executing abilities it's very possible that we got destroyed or something
		if completed {
			// todo(josh): @Optimization: maybe advance a cursor along the array instead of just always using [0] as the current command
			ordered_remove(&queued_commands, 0);
		}
	}
}

destroy__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	// todo(josh): @Alloc: pool these or something?
	delete(queued_commands);
	delete(command_blockers);
}








DISTANCE_BUFFER_DEFAULT :: 0.25;
do_move_command :: proc(me: ^Transform, target: Vec3, speed: f32, range : f32 = DISTANCE_BUFFER_DEFAULT) -> bool {
	// note(josh): do the check first so we can't move _and_ do another action in the same frame
	if close_enough(me.position, target, range) {
		return true;
	}
	me.position += norm0(target - me.position) * speed * wb.fixed_delta_time;
	return false;
}
close_enough :: inline proc(a, b: Vec3, range : f32 = DISTANCE_BUFFER_DEFAULT) -> bool {
	return wb.sqr_magnitude(a - b) < range * range;
}

Unit_Command :: struct {
	kind: union {
		Move_Command,
		Patrol_Command,
		Approach_Command,

		Attack_Command,
		Ability_Command,
	},
}

Move_Command :: struct {
	target: Vec3,
}

Patrol_Command :: struct {
	point1: Vec3,
	point2: Vec3,

	go_to_1: bool,
}

Approach_Command :: struct {
	target: Entity,
}

Attack_Command :: struct {
	target: Entity,
}

Ability_Command :: struct {
	ability: string,
	cursor_position_on_terrain: Vec3,
	target: Entity,
}

/*
note(josh):
We'll likely have a bunch of things that would block a unit from moving
such as attack recovery times or waiting on an animation to complete or
the dialog system blocking control until a conversation is over
*/
Command_Blocker :: struct {
	kind: union {
		Timed_Blocker,
	},
}

Timed_Blocker :: struct {
	time_left: f32,
}

add_timed_blocker :: proc(unit: ^Unit_Component, duration: f32) {
	append(&unit.command_blockers, Command_Blocker{Timed_Blocker{duration}});
}



Health_Component :: struct {
	using base: Component_Base,

	health: int,
	invincible: bool,
}

health_component :: inline proc(health: int, invincible := false) -> Health_Component {
	return Health_Component{{}, health, invincible};
}

take_damage :: inline proc(using comp: ^Health_Component, damage: int) {
	if invincible {
		logln("invincible!!!");
		return;
	}

	health -= damage;
	if health <= 0 {
		health = 0;
		destroy_entity(entity);
	}
	logln("dealt ", damage, " damage. health left: ", health);
}

Attack_Default_Command :: struct {
	using base: Component_Base,
}
