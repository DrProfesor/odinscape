7 Spawner
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
Enemy_Spawner
{
	base {
		enabled true
	}
	current_spawned 0
	last_spawn_time 0.000
	spawn_max 1
	spawn_rate 5.000
	radius 20.000
	enemy_name "Enemy"
}
