"nil"
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

	texture_handle 2

	shader_handle 6

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

