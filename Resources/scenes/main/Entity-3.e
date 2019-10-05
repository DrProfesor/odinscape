3 Entity
Transform
{
	base {
		enabled true
	}
	position [
		-0.726
		-0.934
		0.482
	]

	rotation {
		x -1.000
		y 0.000
		z 0.000
		w 1.000
	}
	scale [
		0.200
		0.200
		0.010
	]

}
Model_Renderer
{
	base {
		enabled true
	}
	model_id "PBOX33_Grass_01"
	texture_id "Plane_Grass_01"
	shader "lit"

	color {
		r 1.000
		g 1.000
		b 1.000
		a 1.000
	}
	material {
		ambient {
			r 1.000
			g 0.500
			b 0.300
			a 1.000
		}
		diffuse {
			r 1.000
			g 0.500
			b 0.300
			a 1.000
		}
		specular {
			r 0.500
			g 0.500
			b 0.500
			a 1.000
		}
		shine 32.000
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
			35.000
			1.800
			35.000
		]

	}
}
