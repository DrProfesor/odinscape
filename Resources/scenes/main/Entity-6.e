6 Entity
Transform
{
	base {
		enabled true
	}
	position [
		0.000
		0.000
		0.000
	]
	rotation {
		x 0.000
		y 0.000
		z 0.000
		w 1.000
	}
	scale [
		1.000
		1.000
		1.000
	]
	parent 0
}
Model_Renderer
{
	base {
		enabled true
	}
	model_id "gronk"
	texture_id "OrcGreen"
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
		0.010
		0.010
		0.010
	]
}
Enemy
{
	base {
		enabled true
	}
	target_position [
		0.000
		0.000
		0.000
	]
	player_path [
	]
	path_idx 0
}
