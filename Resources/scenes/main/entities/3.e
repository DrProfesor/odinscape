"nil"
Transform
{
	base {
		entity 3
	}

	position [
		0.642
		0.991
		0.988
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

Mesh_Renderer
{
	base {
		entity 3
	}

	model "gronk"
	offset_from_transform [
		0.000
		0.000
		0.000
	]

	color {
		r 0.000
		g 1.000
		b 0.000
		a 1.000
	}

	texture_handle 3

	shader_handle 6

}

Box_Collider
{
	base {
		entity 3
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

Player_Component
{
	base {
		entity 3
	}

}

Unit_Component
{
	base {
		entity 3
	}

	move_speed 5.000
	attack_damage 1
	attack_range 2.000
	attack_cooldown 0.500
	attack_recovery 0.000
	cur_attack_cooldown 0.000
	}

