package entity

import "core:os"

import "shared:wb"
import "shared:wb/wbml"

g_prefabs: map[string]^Prefab = make(map[string]^Prefab, 128);

Prefab :: struct {
	name: string,
	path: string,
	entities: [dynamic]Serializable_Entity_Container,
}

init_prefabs :: proc() {
	wb.add_custom_asset_type(Prefab, "pfb", load_prefab, delete_prefab);
}

load_prefab :: proc(name, extension, path: string, data: []byte) -> ^Prefab {
	pfb: Prefab;
	wbml.deserialize(data, &pfb, context.allocator, context.allocator);

	pfb.path = path;

	g_prefabs[name] = new_clone(pfb);
	return g_prefabs[name];
}

delete_prefab :: proc(prefab: ^Prefab) {
	free(prefab);
	delete_key(&g_prefabs, prefab.name);
}

create_prefab :: proc(root_entity: ^Entity, name, path: string) -> ^Prefab {
	add_and_recurse :: proc(entity: ^Entity, entity_array: ^[dynamic]Serializable_Entity_Container, is_root := false) {		
		parent := "";
		if !is_root && entity.parent != nil do parent = entity.parent.uuid;
		container := Serializable_Entity_Container { entity^, parent};

		for child in entity.children {
			add_and_recurse(child, entity_array);
		}
	}

	pfb: Prefab;
	pfb.name = name;
	pfb.path = path;
	add_and_recurse(root_entity, &pfb.entities, true);
	pfb_ptr := new_clone(pfb);
	g_prefabs[name] = pfb_ptr;

	pfb_data := wbml.serialize(&pfb);
	ok := os.write_entire_file(path, transmute([]byte)pfb_data);
	assert(ok, path);

	return pfb_ptr;
}

instantiate_prefab :: proc(name: string) -> ^Entity {
	assert(name in g_prefabs);

	to_parent: map[int]string;
	defer delete(to_parent);
	entities_added: [dynamic]^Entity;
	defer delete(entities_added);

	root: ^Entity;

	for sec in g_prefabs[name].entities {
		e := add_entity(sec.entity);
		if sec.parent != "" {
			to_parent[e.id] = sec.parent;
		} else {
			root = e;
		}
		append(&entities_added, e);
	}

	assert(root != nil, name);

	// This seems pretty slow
	for eid, pid in to_parent {
		for entity in entities_added {
			if entity.uuid == pid {
				set_parent(eid, entity.id);
				break;
			}
		}
	}

	return root;
}


