package entity

import "core:fmt"
import "core:strings"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"

import "../util"
import "../shared"
import "../save"
import "../configs"

MAX_ENTITIES :: 4096;

all_entities: [MAX_ENTITIES]Entity;

// Start at 1 to avoid any default value nonsense with ids
last_entity_slot := 1;
available_entity_slots: [dynamic]int;

Entity :: struct {
	kind: Entity_Union,

	name: string,

	id: int `wbml_noserialize`,
	network_id: int `wbml_noserialize`, // -1 for non networked
	controlling_client: int `wbml_noserialize`,

	position: wb.Vector3,
	rotation: wb.Quaternion,
	scale   : wb.Vector3,

	current_scene: string,
	uuid: string,

	active: bool,
	dynamically_spawned: bool,

	parent: ^Entity `wbml_noserialize`,
	children: [dynamic]^Entity `wbml_noserialize`,
}

_create_entity :: proc(pos := wb.Vector3{}, rotation := wb.Quaternion(1), scale := wb.Vector3{1,1,1}, dynamic_spawn := true) -> Entity {
	e : Entity;
	
	e.network_id = -1;
	e.position = pos;
	e.rotation = rotation;
	e.scale = scale;
	e.dynamically_spawned = dynamic_spawn;

	return e;
}

create_entity :: proc(pos := wb.Vector3{}, rotation := wb.Quaternion(1), scale := wb.Vector3{1,1,1}, dynamic_spawn := true) -> ^Entity {
	id := last_entity_slot;
	if len(available_entity_slots) > 0 {
		id = available_entity_slots[len(available_entity_slots)];
		pop(&available_entity_slots);
	} else {
		last_entity_slot += 1;
	}

	all_entities[id] = _create_entity(pos, rotation, scale, dynamic_spawn);
	e := &all_entities[id];

	e.id = id;
	e.name = strings.clone(util.tprint("New Entity (", id, ")"));
	e.active = true;

	return e;
}

add_entity :: proc(_e: Entity) -> ^Entity {
	entity := _e;

	id := last_entity_slot;
	if len(available_entity_slots) > 0 {
		id = available_entity_slots[len(available_entity_slots)];
		pop(&available_entity_slots);
	} else {
		last_entity_slot += 1;
	}

	entity.id = id;
	entity.network_id = -1;
	entity.active = true;

	if entity.name == "" {
		entity.name = strings.clone(util.tprint("New Entity (", id, ")"));
	}

	// this is currently only used for loading from a scene. so that is never dynamic
	entity.dynamically_spawned = false;

	all_entities[id] = entity;

	_add_entity(&all_entities[id]);

	return &all_entities[id];
}

get_entity :: proc(id: int) -> ^Entity {
	if id <= 0 do return nil;
	if id >= len(all_entities) do return nil;

	e := &all_entities[id];

	if !e.active do return nil;

	return e;
}

set_parent :: proc {set_parent_id, set_parent_inst}; 

set_parent_id :: proc(target, parent: int) {
	if target == parent do return;

	t := &all_entities[target];
	p := &all_entities[parent];
	assert(t.active);
	assert(p.active);
	set_parent_inst(t,p);
}

set_parent_inst :: proc(target, parent: ^Entity) {
	if target == parent do return;

	if target.parent != nil {
		for c, i in target.parent.children {
			if c == target {
				unordered_remove(&target.parent.children, i);
				break;
			}
		}
	}

	target.parent = parent;
	if parent != nil {
		append(&parent.children, target);
	}
}

destroy_entity :: proc(id: int) {
	e := &all_entities[id];

	if !e.active do return;

	_destroy_entity(&all_entities[id]);

	append(&available_entity_slots, id);
	all_entities[id].active = false;
}

init :: proc() {
	init_prefabs();
}

logln :: logging.logln;