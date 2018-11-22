package main

using import    "core:fmt"
using import    "core:math"
	  import    "core:mem"

	  import wb "shared:workbench"
	  import ai "shared:workbench/external/assimp"
	  import coll "shared:workbench/collision"

Unit_Component :: struct {
	entity: Entity,

	move_speed: f32,

	using runtime_values: struct {
		has_target: bool,
		current_target: Vec3,
	}
}

update__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	if has_target {
		tf := get_component(entity, Transform);
		if wb.sqr_magnitude(tf.position - current_target) < 0.01 {
			has_target = false;
		}
		else {
			tf.position += norm(current_target - tf.position) * move_speed * wb.fixed_delta_time;
		}
	}
}