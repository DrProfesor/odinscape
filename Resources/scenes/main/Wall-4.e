4 Wall
Transform
{
	base {
		enabled true
	}
	position [
		-10.220
		-1.728
		7.091
	]
	rotation {
		x -0.479
		y 0.485
		z 0.515
		w 0.520
	}
	scale [
		0.020
		0.020
		0.100
	]
	parent 0
}
Model_Renderer
{
	base {
		enabled true
	}
	model_id "PBOX33_Grass_01"
	texture_id "Plane_Grass_01"
	shader_id "lit"
	color {
		r 1.000
		g 1.000
		b 1.000
		a 1.000
	}
	material {
		metallic 0.500
		roughness 0.500
		ao 0.500
	}
	scale [
		1.000
		1.000
		1.000
	]
}
Collider
{
	base {
		enabled true
	}
	type Box
	box {
		size [
			4.000
			10.000
			4.000
		]
	}
}
