package entity

import "core:os"
import "core:fmt"
import "core:strings"

import "../util"
import "shared:wb/basic"
import "shared:wb/wbml"
import "shared:wb/reflection"
import "shared:wb/allocators"

SCENE_DIR :: "resources/scenes";

loaded_scenes: map[string]^Scene;
main_scene: ^Scene;

Scene :: struct {
	id: string,
	entities: map[int]^Entity,
	dirty: bool,
}

load_scene :: proc(scene_id: string, set_main := false) {
	scene_path := util.tprint(SCENE_DIR, "/", scene_id);

	entity_wbml_node_arena: allocators.Arena;
    allocators.init_arena(&entity_wbml_node_arena, make([]byte, 1 * 1024 * 1024), true);
    defer delete(entity_wbml_node_arena.memory);
    entity_wbml_node_arena.panic_on_oom = true;

    to_parent: map[int]string;
    defer delete(to_parent);

	scene: Scene;
	scene.id = scene_id;
	for entity_file in basic.get_all_filepaths_recursively(scene_path) {
		bytes, ok := os.read_entire_file(entity_file);
		assert(ok);

		sec: Serializable_Entity_Container;
		wbml.deserialize(bytes, &sec, allocators.arena_allocator(&entity_wbml_node_arena), context.allocator);

		entity := add_entity(sec.entity);
		scene.entities[entity.id] = entity;

		if sec.parent != "" {
			to_parent[entity.id] = sec.parent;
		}
	}

	// This seems pretty slow
	for eid, pid in to_parent {
		for e in scene.entities {
			entity := get_entity(e);
			if entity.uuid == pid {
				set_parent(eid, entity.id);
				break;
			}
		}
	}

	ns := new_clone(scene);

	if set_main do main_scene = ns;
	loaded_scenes[scene_id] = ns;
}

entity_files_to_delete: map[string][dynamic]string;

save_scene :: proc(scene_id: string) {
	assert(scene_id in loaded_scenes);
	scene := loaded_scenes[scene_id];

	if scene_id in entity_files_to_delete {
		for file in entity_files_to_delete[scene_id] {
			basic.delete_file(file);
			delete(file);
		}
		clear(&entity_files_to_delete[scene_id]);
	}

	if !basic.is_directory(fmt.tprintf("%s/%s", SCENE_DIR, scene_id)) do
		basic.create_directory(fmt.tprintf("%s/%s", SCENE_DIR, scene_id));

	// TODO save only changed entities
	for eid, entity in scene.entities {
		file_path := fmt.tprintf("%s/%s/%s.e", SCENE_DIR, scene_id, entity.uuid);

		sec: Serializable_Entity_Container;
		sec.entity = entity^;
		if entity.parent != nil {
			sec.parent = entity.parent.uuid;
		}

		data := wbml.serialize(&sec);
		ok := os.write_entire_file(file_path, transmute([]byte)data);
		assert(ok, file_path);
	}

	scene.dirty = false;
}

save_all :: proc() {
	for scene_id, _ in loaded_scenes {
		save_scene(scene_id);
	}
}

unload_scene :: proc(scene_id: string) {

}

dirty_scene :: proc(scene_id: string = "") {
	scene_id := scene_id;
	if scene_id == "" do scene_id = main_scene.id;
	loaded_scenes[scene_id].dirty = true;
}

add_entity_to_scene :: proc(e: ^Entity, _scene: string = "") {
	assert(e != nil);

	scene_id := _scene;
	if scene_id == "" do scene_id = main_scene.id;
	if e.dynamically_spawned do return; 

	assert(scene_id != "", "No scene loaded");
	
	remove_from_scene(e);

	scene := loaded_scenes[scene_id];
	scene.entities[e.id] = e;
	e.current_scene = scene_id;
	e.uuid = strings.clone(util.uuid_create_string());

	for child in e.children {
		child.current_scene = scene_id;
	}
}

remove_from_scene :: proc(e: ^Entity) {
	assert(e != nil);

	if e.current_scene == "" do return;

	current_scene := loaded_scenes[e.current_scene];
	delete_key(&current_scene.entities, e.id);

	if e.current_scene not_in entity_files_to_delete {
		entity_files_to_delete[e.current_scene] = make([dynamic]string, 0, 1);
	}

	append(&entity_files_to_delete[e.current_scene], strings.clone(fmt.tprintf("%s/%s/%s.e", SCENE_DIR, e.current_scene, e.uuid)));
}

Serializable_Entity_Container :: struct {
	entity: Entity,
	parent: string,
}