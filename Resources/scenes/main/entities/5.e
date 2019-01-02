Mesh_Renderer
{
	base {
		entity 5

	}

	model "gronk"
	offset_from_transform [
		0.000
		0.000
		0.000
	]

	color {
		r 1.000
		g 1.000
		b 1.000
		a 1.000
	}

	texture_handle 3

	shader_handle 6

}

Unit_Component
{
	base {
		entity 5

	}

	move_speed 5.000
	attack_damage 1
	attack_range 2.000
	attack_cooldown 0.500
	attack_recovery 0.000
	cur_attack_cooldown 0.000
	abilities 
	command_blockers [
	]
	queued_commands [
	]
}

Health_Component
{
	base {
		entity 5

	}

	health 10
	invincible false
}

Attack_Default_Command
{
	base {
		entity 5

	}

}

Transform
{
	base {
		entity 5

	}

	position [
		-3.000
		0.000
		3.000
	]

	scale [
		1.000
		1.000
		1.000
	]

	rotation [
		0.000
		0.000
		0.000
	]

	stuck_on_ground true
	offset_from_ground [
		0.000
		0.000
		0.000
	]

}

Box_Collider
{
	base {
		entity 5

	}

	offset_from_transform [
		0.000
		0.500
		0.000
	]

	size [
		1.000
		1.000
		1.000
	]

}

