package entity

import "core:os"

import "../util"
import "shared:wb/basic"
import "shared:wb/wbml"

SCENE_DIR :: "resources/scenes";

loaded_scenes: map[string]Scene;
main_scene: string;

Scene :: struct {
	entities: [MAX_ENTITIES]int,
	total_entities: int,
}

load_scene :: proc(scene_id: string, set_main := false) {
	scene_path := util.tprint(SCENE_DIR, "/", scene_id);

	scene: Scene;
	for entity_file in basic.get_all_filepaths_recursively(scene_path) {
		bytes, ok := os.read_entire_file(entity_file);
		assert(ok);

		e: Entity;
		wbml.deserialize(bytes, &e, context.allocator, context.allocator);

		entity := add_entity(e);
		scene.entities[scene.total_entities] = entity.id;

		scene.total_entities += 1;
	}

	if set_main || main_scene == "" {
		main_scene = scene_id;
	}

	loaded_scenes[scene_id] = scene;
}

instantiate_entity_in_scene :: proc(scene, prefab: string) {

}

unload_scene :: proc(scene_id: string) {
	// iterate scene entites and destroy
}