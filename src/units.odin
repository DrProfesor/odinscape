package main

using import    "core:fmt"
using import    "core:math"
	  import    "core:mem"

	  import wb "shared:workbench"
	  import ai "shared:workbench/external/assimp"
	  import coll "shared:workbench/collision"

Unit_Component :: struct {
	using base: Component_Base,

	move_speed: f32,

	attack_damage: int,
	attack_range: f32,
	attack_cooldown: f32,
	cur_attack_cooldown: f32,

	queued_commands: [dynamic]Unit_Command,
}

unit_component :: proc(move_speed: f32, damage: int, range: f32, cooldown: f32) -> Unit_Component {
	unit: Unit_Component;
	unit.move_speed = move_speed;
	unit.attack_damage = damage;
	unit.attack_range = range;
	unit.attack_cooldown = cooldown;
	return unit;
}

update__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	cur_attack_cooldown -= wb.fixed_delta_time;
	if cur_attack_cooldown < 0 do cur_attack_cooldown = 0;

	if len(queued_commands) == 0 do return;

	base_command := &queued_commands[0];
	completed := false;

	// note(josh): @UnitCommandCompleteSwitch: #complete doesn't seem to be working here
	// #complete switch command_kind in command {

	switch command in &base_command.kind {
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

		case Attack_Command: {
			tf := get_component(entity, Transform);
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
				other_health.health -= attack_damage;
				if other_health.health <= 0 {
					other_health.health = 0;
					destroy_entity(command.target);
				}
				logln("dealt ", attack_damage, " damage. health left: ", other_health.health);
				cur_attack_cooldown = attack_cooldown;
			}
		}
	}

	if completed {
		// todo(josh): @Optimization: maybe advance a cursor along the array instead of just always using [0] as the current command
		ordered_remove(&queued_commands, 0);
	}
}

destroy__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	// todo(josh): @Alloc: pool these or something?
	delete(queued_commands);
}

DISTANCE_BUFFER_DEFAULT :: 0.25;
do_move_command :: proc(me: ^Transform, target: Vec3, speed: f32, range : f32 = DISTANCE_BUFFER_DEFAULT) -> bool {
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
		Attack_Command,
		Patrol_Command,
		Approach_Command,
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

Attack_Command :: struct {
	target: Entity,
}

Approach_Command :: struct {
	target: Entity,
}





Health_Component :: struct {
	using base: Component_Base,

	health: int,
}

Attack_Default_Command :: struct {
	using base: Component_Base,
}