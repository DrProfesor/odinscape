Mesh_Renderer
{
	base {
		entity 6
	}

	model "cube"
	offset_from_transform [
		0.000
		0.500
		0.000
	]

	color {
		r 1.000
		g 1.000
		b 1.000
		a 1.000
	}

	texture_handle 0

	shader_handle 6

}

Health_Component
{
	base {
		entity 6
	}

	health 100
	invincible true
}

Attack_Default_Command
{
	base {
		entity 6
	}

}

Transform
{
	base {
		entity 6
	}

	position [
		3.000
		1.000
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
		entity 6
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

