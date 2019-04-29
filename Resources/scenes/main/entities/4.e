"nil"
Transform
{
	base {
		entity 4
	}

	position [
		-1.008
		0.000
		2.749
	]

	scale [
		1.000
		1.000
		1.000
	]

	orientation {
		x 0.000
		y -0.560
		z 0.000
		w 0.829
	}

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
		entity 4
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

	texture_handle 5

	shader_handle 6

}

Box_Collider
{
	base {
		entity 4
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

Unit_Component
{
	base {
		entity 4
	}

	move_speed 5.000
	attack_damage 1
	attack_range 2.000
	attack_cooldown 0.500
	attack_recovery 0.000
	cur_attack_cooldown 0.000
	}

