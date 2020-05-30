package game

import "core:time"
import "core:fmt"

import wb "shared:wb"
import "shared:wb/ecs"
import "shared:wb/math"

import "../configs"
import "../physics"
import "../net"
import "../shared"

// Enemy spawners
init_enemy_spawner :: proc(using spawner: ^Enemy_Spawner) {
	spawn_max = 1;
	spawn_rate = 5;
	radius = 20;
	enemy_name = "Enemy";
}

update_enemy_spawner :: proc(using spawner: ^Enemy_Spawner, dt: f32) {
	when !#config(HEADLESS, false) do return;
	else {
		current_seconds := f64(time.now()._nsec) / f64(time.Second);
		
		if current_seconds < last_spawn_time + spawn_rate do return;
		if current_spawned >= spawn_max do return;

		t := math.TAU * wb.random01();
		u := wb.random01() + wb.random01();
		r := u>1 ? 2-u : u;
		x := r * math.cos(t);
		z := r * math.sin(t);
		y := get_terrain_height_at_position({x,0,z});

		// TODO (jake): pull this logic into a "network_instantiate"
		prefab := prefab_scene.prefabs[fmt.tprint("resources/Prefabs/", enemy_name, ".e")];
		enemy := ecs.instantiate_prefab(prefab);

		enemy_transform, ete := ecs.get_component(enemy, Transform);
		assert(ete);
		enemy_transform.position = {x, y, z};

		net.network_entity(enemy, 0);

		current_spawned += 1;
		last_spawn_time = current_seconds;
	}
}

Enemy_Spawner :: struct {
	using base: ecs.Component_Base,

	current_spawned: int "imgui_allow64bit",
	last_spawn_time: f64 "imgui_allow64bit",

	spawn_max: int "imgui_allow64bit",
	spawn_rate: f64 "imgui_allow64bit",
	radius: f32,
	enemy_name: string,
}


// Enemies
init_enemy :: proc(using enemy: ^Enemy) {
	target_network_id = -1;

	base_move_speed = 1;
	target_distance_from_target = 1;
	detection_radius = 10;
	cutoff_radius = 10;

	when !#config(HEADLESS, false) {
		model, mok := ecs.get_component(e, Model_Renderer);
        assert(mok);
        model.model_id = "gronk";
        model.texture_id = "OrcGreen";
        model.scale = {1, 1, 1};
        model.color = {1, 1, 1, 1};
        model.shader_id = "lit";
        model.material = wb.Material {
            0.5,0.5,0.5
        };
	}
}

update_enemy :: proc(using enemy: ^Enemy, dt: f32) {
	transform, ok := ecs.get_component(e, Transform);

	when #config(HEADLESS, false) {
		if target_network_id == -1 {
			@static active_player_componenets: [dynamic]Player_Entity;
			clear(&active_player_componenets);
			ecs.get_active_component_storage(Player_Entity, &active_player_componenets);

			for player in active_player_componenets {
				player_transform, exists := ecs.get_component(player.e, Transform);
				assert(exists);
				
				player_net_id, exists2 := ecs.get_component(player.e, net.Network_Id);
				assert(exists2);

				dist := math.magnitude(player_transform.position - transform.position);
				if dist <= detection_radius {
					target_network_id = player_net_id.network_id;
					break;
				}
			}
		}
	}

	if target_network_id == -1 do return;
	
	target_entity := net.get_entity_from_network_id(target_network_id);

	if target_entity < 0  {
		target_network_id = -1;
		return;
	}

	target_transform, exists3 := ecs.get_component(target_entity, Transform);

	if !exists3 {
		target_network_id = -1;
		return;
	}

	direction_to_target := math.norm(target_transform.position - transform.position);
	distance_to_target := math.magnitude(target_transform.position - transform.position);
	target_pos := transform.position + direction_to_target * (distance_to_target - target_distance_from_target);

	when #config(HEADLESS, false) {
		if target_pos != target_position { // position has changed, refresh the pathfinding
			target_position = target_pos;
			path = physics.smooth_a_star(transform.position, target_position, 0.5);
	        path_idx = 1;
		}
	}

	distance_to_point := math.magnitude(target_pos - transform.position);
	if distance_to_point > 0.1 {
		p := target_position;
        if path_idx < len(path)-1 {
            p = path[path_idx];
            if math.distance(math.Vec3{p.x, 0, p.z}, math.Vec3{transform.position.x, 0, transform.position.z}) < 0.01 {
                path_idx += 1;
            }
        }

        height := get_terrain_height_at_position(transform.position);

        p1 := move_towards(transform.position, p, base_move_speed * dt);
        transform.position = {p1.x, height, p1.z};
        transform.rotation = math.euler_angles(0, look_y_rot(transform.position, p) - math.PI / 2, 0);
	}
}

Enemy :: struct {
    using base: ecs.Component_Base,
    target_position: Vec3 "replicate:server",
    
    path: []Vec3,
	path_idx: int,

	target_network_id: int "replicate:server",

	base_move_speed: f32 "replicate:server", 
	target_distance_from_target: f32 "replicate:server",
	detection_radius: f32 "replicate:server",
	cutoff_radius: f32 "replicate:server",
}