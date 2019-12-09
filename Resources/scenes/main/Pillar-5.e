5 Pillar
Transform
{
	base {
		enabled true
	}
	position [
		-12.368
		-1.424
		0.482
	]

	rotation {
		x -0.707
		y 0.000
		z 0.000
		w 0.707
	}
	scale [
		0.010
		0.010
		0.050
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
	internal_collider {
		position [
			-12.368
			-1.424
			0.482
		]

		box {
			size [
				2.000
				4.000
				2.000
			]

		}
	}
	type Box
	box {
		size [
			2.000
			4.000
			2.000
		]

	}
}
