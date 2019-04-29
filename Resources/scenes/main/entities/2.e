"nil"
Transform
{
	base {
		entity 2
	}

	position [
		2.500
		0.500
		2.500
	]

	scale [
		5.000
		1.000
		5.000
	]

	orientation {
		x 0.000
		y 0.000
		z 0.000
		w 1.000
	}

	rotation [
		0.000
		0.000
		0.000
	]

	stuck_on_ground false
	offset_from_ground [
		0.000
		0.000
		0.000
	]

}

Terrain_Component
{
	base {
		entity 2
	}

}

Mesh_Renderer
{
	base {
		entity 2
	}

	model "cube"
	offset_from_transform [
		0.000
		0.000
		0.000
	]

	color {
		r 0.000
		g 0.000
		b 1.000
		a 1.000
	}

	texture_handle 0

	shader_handle 2

}

Box_Collider
{
	base {
		entity 2
	}

	offset_from_transform [
		0.000
		0.000
		0.000
	]

	size [
		1.000
		1.000
		1.000
	]

}

