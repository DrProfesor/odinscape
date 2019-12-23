6 Pillar
Transform
{
	base {
		enabled true
	}
	position [
		-6.496
		-1.493
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
		enabled false
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
			-6.496
			-1.493
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
Particle_Emitter
{
	base {
		enabled true
	}
	base_emitter {
		position [
			-6.496
			-1.493
			0.482
		]

		rotation {
			x 0.000
			y 0.000
			z 0.000
			w 1.000
		}
		emit true
		emission_rate 4
		max_particles 100
		min_ttl 2.000
		max_ttl 3.000
		initial_colour {
			r 1.000
			g 0.000
			b 0.000
			a 1.000
		}
		final_colour {
			r 0.000
			g 1.000
			b 0.000
			a 0.000
		}
		initial_scale [
			0.100
			0.100
			0.100
		]

		final_scale [
			0.300
			0.300
			0.300
		]

		texture_id "particle"
		emission .Spheric_Emission {
			direction [
				0.000
				1.000
				0.000
			]

			angle_min -45.000
			angle_max 45.000
		}

	}
}
