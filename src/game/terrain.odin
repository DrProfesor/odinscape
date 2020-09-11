package game

import "shared:wb"

terrain_get_height_at_position :: proc(position: Vector3) -> f32 {
	// for terrain in terrains {
	// 	// TODO terrain position
	// 	p, _, hit := wb.raycast_into_terrain(terrain, {0,0,0}, position, Vector3{0, -1, 0});
 //    	if hit { return p.y; }
	// }

	return 0;
}

terrain_get_raycasted_position :: proc(ray_start, ray_dir: Vector3) -> (Vector3, bool) {
	// for terrain in terrains {
	// 	// TODO terrain position
	// 	pos, chunk_idx, hit := wb.raycast_into_terrain(terrain, {0,0,0}, ray_start, ray_dir);	
	// 	if !hit do continue;

	// 	return pos, true;
	// }

	return {0,0,0}, false;
}

// terrains: [dynamic]wb.Terrain;

init_terrain :: proc() {

	// TODO save and load terrain
	// Maybe couple terrain with position?

	// t := wb.create_terrain({64, 256, 64}, 0.5);
	// t.material = { 0.5, 0.5, 0.5 };
	// append(&terrains, t);
}

update_terrain :: proc() {
	// TODO handle updating terrain visibility
}
