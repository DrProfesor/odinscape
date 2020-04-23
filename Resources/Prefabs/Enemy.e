6 Enemy
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
		0.010
		0.010
		0.010
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
	path [
	]
	path_idx 0
	target_network_id -1
	base_move_speed 1.000
	target_distance_from_target 1.000
	detection_radius 10.000
	cutoff_radius 10.000
}
