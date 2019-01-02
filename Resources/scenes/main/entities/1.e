Mesh_Renderer
{
	base {
		entity 1

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

	shader_handle 12

}

Transform
{
	base {
		entity 1

	}

	position [
		0.000
		-0.500
		0.000
	]

	scale [
		10.000
		1.000
		10.000
	]

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

Box_Collider
{
	base {
		entity 1

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

Terrain_Component
{
	base {
		entity 1

	}

}

