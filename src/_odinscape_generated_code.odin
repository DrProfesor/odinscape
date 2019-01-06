package main

using import "core:fmt"
using import "shared:workbench/pool"
      import wb "shared:workbench"
      import imgui "shared:workbench/external/imgui"
      import "shared:workbench/wbml"

Component_Type :: enum {
	Transform,
	Sprite_Renderer,
	Spinner_Component,
	Terrain_Component,
	Mesh_Renderer,
	Box_Collider,
	Unit_Component,
}

all__Transform: Pool(Transform, 64);
all__Sprite_Renderer: Pool(Sprite_Renderer, 64);
all__Spinner_Component: Pool(Spinner_Component, 64);
all__Terrain_Component: Pool(Terrain_Component, 64);
all__Mesh_Renderer: Pool(Mesh_Renderer, 64);
all__Box_Collider: Pool(Box_Collider, 64);
all__Unit_Component: Pool(Unit_Component, 64);

add_component :: proc{add_component_type, add_component_value};

add_component_type :: proc(entity: Entity, $Type: typeid) -> ^Type {
	entity_data, ok := all_entities[entity]; assert(ok);
	defer all_entities[entity] = entity_data;
	when Type == Transform {
		t := pool_get(&all__Transform);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Transform);
		when #defined(init__Transform) {
			init__Transform(t);
		}
		return t;
	}
	when Type == Sprite_Renderer {
		t := pool_get(&all__Sprite_Renderer);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Sprite_Renderer);
		when #defined(init__Sprite_Renderer) {
			init__Sprite_Renderer(t);
		}
		return t;
	}
	when Type == Spinner_Component {
		t := pool_get(&all__Spinner_Component);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Spinner_Component);
		when #defined(init__Spinner_Component) {
			init__Spinner_Component(t);
		}
		return t;
	}
	when Type == Terrain_Component {
		t := pool_get(&all__Terrain_Component);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Terrain_Component);
		when #defined(init__Terrain_Component) {
			init__Terrain_Component(t);
		}
		return t;
	}
	when Type == Mesh_Renderer {
		t := pool_get(&all__Mesh_Renderer);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Mesh_Renderer);
		when #defined(init__Mesh_Renderer) {
			init__Mesh_Renderer(t);
		}
		return t;
	}
	when Type == Box_Collider {
		t := pool_get(&all__Box_Collider);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Box_Collider);
		when #defined(init__Box_Collider) {
			init__Box_Collider(t);
		}
		return t;
	}
	when Type == Unit_Component {
		t := pool_get(&all__Unit_Component);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Unit_Component);
		when #defined(init__Unit_Component) {
			init__Unit_Component(t);
		}
		return t;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml"));
	return nil;
}

add_component_value :: proc(entity: Entity, component: $Type) -> ^Type {
	entity_data, ok := all_entities[entity]; assert(ok);
	defer all_entities[entity] = entity_data;
	component.entity = entity;
	when Type == Transform {
		t := pool_get(&all__Transform);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Transform);
		when #defined(init__Transform) {
			init__Transform(t);
		}
		return t;
	}
	when Type == Sprite_Renderer {
		t := pool_get(&all__Sprite_Renderer);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Sprite_Renderer);
		when #defined(init__Sprite_Renderer) {
			init__Sprite_Renderer(t);
		}
		return t;
	}
	when Type == Spinner_Component {
		t := pool_get(&all__Spinner_Component);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Spinner_Component);
		when #defined(init__Spinner_Component) {
			init__Spinner_Component(t);
		}
		return t;
	}
	when Type == Terrain_Component {
		t := pool_get(&all__Terrain_Component);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Terrain_Component);
		when #defined(init__Terrain_Component) {
			init__Terrain_Component(t);
		}
		return t;
	}
	when Type == Mesh_Renderer {
		t := pool_get(&all__Mesh_Renderer);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Mesh_Renderer);
		when #defined(init__Mesh_Renderer) {
			init__Mesh_Renderer(t);
		}
		return t;
	}
	when Type == Box_Collider {
		t := pool_get(&all__Box_Collider);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Box_Collider);
		when #defined(init__Box_Collider) {
			init__Box_Collider(t);
		}
		return t;
	}
	when Type == Unit_Component {
		t := pool_get(&all__Unit_Component);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Unit_Component);
		when #defined(init__Unit_Component) {
			init__Unit_Component(t);
		}
		return t;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml"));
	return nil;
}

get_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	when Type == Transform {
		for _, batch_idx in &all__Transform.batches {
			batch := &all__Transform.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Sprite_Renderer {
		for _, batch_idx in &all__Sprite_Renderer.batches {
			batch := &all__Sprite_Renderer.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Spinner_Component {
		for _, batch_idx in &all__Spinner_Component.batches {
			batch := &all__Spinner_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Terrain_Component {
		for _, batch_idx in &all__Terrain_Component.batches {
			batch := &all__Terrain_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Mesh_Renderer {
		for _, batch_idx in &all__Mesh_Renderer.batches {
			batch := &all__Mesh_Renderer.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Box_Collider {
		for _, batch_idx in &all__Box_Collider.batches {
			batch := &all__Box_Collider.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Unit_Component {
		for _, batch_idx in &all__Unit_Component.batches {
			batch := &all__Unit_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml"));
	return nil;
}

call_component_updates :: proc() {
	when #defined(update__Transform) {
		for _, batch_idx in &all__Transform.batches {
			batch := &all__Transform.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Transform(c);
			}
		}
	}
	when #defined(update__Sprite_Renderer) {
		for _, batch_idx in &all__Sprite_Renderer.batches {
			batch := &all__Sprite_Renderer.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Sprite_Renderer(c);
			}
		}
	}
	when #defined(update__Spinner_Component) {
		for _, batch_idx in &all__Spinner_Component.batches {
			batch := &all__Spinner_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Spinner_Component(c);
			}
		}
	}
	when #defined(update__Terrain_Component) {
		for _, batch_idx in &all__Terrain_Component.batches {
			batch := &all__Terrain_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Terrain_Component(c);
			}
		}
	}
	when #defined(update__Mesh_Renderer) {
		for _, batch_idx in &all__Mesh_Renderer.batches {
			batch := &all__Mesh_Renderer.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Mesh_Renderer(c);
			}
		}
	}
	when #defined(update__Box_Collider) {
		for _, batch_idx in &all__Box_Collider.batches {
			batch := &all__Box_Collider.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Box_Collider(c);
			}
		}
	}
	when #defined(update__Unit_Component) {
		for _, batch_idx in &all__Unit_Component.batches {
			batch := &all__Unit_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Unit_Component(c);
			}
		}
	}
}

call_component_renders :: proc() {
	when #defined(render__Transform) {
		for _, batch_idx in &all__Transform.batches {
			batch := &all__Transform.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Transform(c);
			}
		}
	}
	when #defined(render__Sprite_Renderer) {
		for _, batch_idx in &all__Sprite_Renderer.batches {
			batch := &all__Sprite_Renderer.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Sprite_Renderer(c);
			}
		}
	}
	when #defined(render__Spinner_Component) {
		for _, batch_idx in &all__Spinner_Component.batches {
			batch := &all__Spinner_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Spinner_Component(c);
			}
		}
	}
	when #defined(render__Terrain_Component) {
		for _, batch_idx in &all__Terrain_Component.batches {
			batch := &all__Terrain_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Terrain_Component(c);
			}
		}
	}
	when #defined(render__Mesh_Renderer) {
		for _, batch_idx in &all__Mesh_Renderer.batches {
			batch := &all__Mesh_Renderer.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Mesh_Renderer(c);
			}
		}
	}
	when #defined(render__Box_Collider) {
		for _, batch_idx in &all__Box_Collider.batches {
			batch := &all__Box_Collider.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Box_Collider(c);
			}
		}
	}
	when #defined(render__Unit_Component) {
		for _, batch_idx in &all__Unit_Component.batches {
			batch := &all__Unit_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Unit_Component(c);
			}
		}
	}
}

serialize_entity_components :: proc(entity: Entity) -> string {
	serialized : String_Buffer;
	sbprint(&serialized, tprint("\"", all_entities[entity].name, "\"", "\n"));
	Transform_comp := get_component(entity, Transform);
	if Transform_comp != nil {
		s := wbml.serialize(Transform_comp);
		sbprint(&serialized, "Transform\n");
		sbprint(&serialized, s);
	}
	Sprite_Renderer_comp := get_component(entity, Sprite_Renderer);
	if Sprite_Renderer_comp != nil {
		s := wbml.serialize(Sprite_Renderer_comp);
		sbprint(&serialized, "Sprite_Renderer\n");
		sbprint(&serialized, s);
	}
	Spinner_Component_comp := get_component(entity, Spinner_Component);
	if Spinner_Component_comp != nil {
		s := wbml.serialize(Spinner_Component_comp);
		sbprint(&serialized, "Spinner_Component\n");
		sbprint(&serialized, s);
	}
	Terrain_Component_comp := get_component(entity, Terrain_Component);
	if Terrain_Component_comp != nil {
		s := wbml.serialize(Terrain_Component_comp);
		sbprint(&serialized, "Terrain_Component\n");
		sbprint(&serialized, s);
	}
	Mesh_Renderer_comp := get_component(entity, Mesh_Renderer);
	if Mesh_Renderer_comp != nil {
		s := wbml.serialize(Mesh_Renderer_comp);
		sbprint(&serialized, "Mesh_Renderer\n");
		sbprint(&serialized, s);
	}
	Box_Collider_comp := get_component(entity, Box_Collider);
	if Box_Collider_comp != nil {
		s := wbml.serialize(Box_Collider_comp);
		sbprint(&serialized, "Box_Collider\n");
		sbprint(&serialized, s);
	}
	Unit_Component_comp := get_component(entity, Unit_Component);
	if Unit_Component_comp != nil {
		s := wbml.serialize(Unit_Component_comp);
		sbprint(&serialized, "Unit_Component\n");
		sbprint(&serialized, s);
	}
	return to_string(serialized);
}

init_entity :: proc(entity: Entity) -> bool {
	when #defined(init__Transform) {
		Transform_comp := get_component(entity, Transform);
		if Transform_comp != nil {
			init__Transform(Transform_comp);
		}
	}
	when #defined(init__Sprite_Renderer) {
		Sprite_Renderer_comp := get_component(entity, Sprite_Renderer);
		if Sprite_Renderer_comp != nil {
			init__Sprite_Renderer(Sprite_Renderer_comp);
		}
	}
	when #defined(init__Spinner_Component) {
		Spinner_Component_comp := get_component(entity, Spinner_Component);
		if Spinner_Component_comp != nil {
			init__Spinner_Component(Spinner_Component_comp);
		}
	}
	when #defined(init__Terrain_Component) {
		Terrain_Component_comp := get_component(entity, Terrain_Component);
		if Terrain_Component_comp != nil {
			init__Terrain_Component(Terrain_Component_comp);
		}
	}
	when #defined(init__Mesh_Renderer) {
		Mesh_Renderer_comp := get_component(entity, Mesh_Renderer);
		if Mesh_Renderer_comp != nil {
			init__Mesh_Renderer(Mesh_Renderer_comp);
		}
	}
	when #defined(init__Box_Collider) {
		Box_Collider_comp := get_component(entity, Box_Collider);
		if Box_Collider_comp != nil {
			init__Box_Collider(Box_Collider_comp);
		}
	}
	when #defined(init__Unit_Component) {
		Unit_Component_comp := get_component(entity, Unit_Component);
		if Unit_Component_comp != nil {
			init__Unit_Component(Unit_Component_comp);
		}
	}
	return true;
}

deserialize_entity_comnponents :: proc(entity_id: int, serialized_entity: [dynamic]string, component_types: [dynamic]string, entity_name: string) -> Entity {
	entity := new_entity_dangerous(entity_id, entity_name);
	for component_data, i in serialized_entity {
		component_type := component_types[i];
		switch component_type {
			case "Transform": {
				component := wbml.deserialize(Transform, component_data);
				add_component(entity, component);
			}
			case "Sprite_Renderer": {
				component := wbml.deserialize(Sprite_Renderer, component_data);
				add_component(entity, component);
			}
			case "Spinner_Component": {
				component := wbml.deserialize(Spinner_Component, component_data);
				add_component(entity, component);
			}
			case "Terrain_Component": {
				component := wbml.deserialize(Terrain_Component, component_data);
				add_component(entity, component);
			}
			case "Mesh_Renderer": {
				component := wbml.deserialize(Mesh_Renderer, component_data);
				add_component(entity, component);
			}
			case "Box_Collider": {
				component := wbml.deserialize(Box_Collider, component_data);
				add_component(entity, component);
			}
			case "Unit_Component": {
				component := wbml.deserialize(Unit_Component, component_data);
				add_component(entity, component);
			}
		}
	}
	return entity;
}

destroy_marked_entities :: proc() {
	for entity_id in entities_to_destroy {
		entity, ok := all_entities[entity_id]; assert(ok);
		for comp_type in entity.component_types {
			switch comp_type {
			case Component_Type.Transform: {
				pool_loop__Transform:
				for _, batch_idx in &all__Transform.batches {
					batch := &all__Transform.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Transform) {
								destroy__Transform(comp);
							}
							pool_return(&all__Transform, comp);
							break pool_loop__Transform;
						}
					}
				}
			}
			case Component_Type.Sprite_Renderer: {
				pool_loop__Sprite_Renderer:
				for _, batch_idx in &all__Sprite_Renderer.batches {
					batch := &all__Sprite_Renderer.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Sprite_Renderer) {
								destroy__Sprite_Renderer(comp);
							}
							pool_return(&all__Sprite_Renderer, comp);
							break pool_loop__Sprite_Renderer;
						}
					}
				}
			}
			case Component_Type.Spinner_Component: {
				pool_loop__Spinner_Component:
				for _, batch_idx in &all__Spinner_Component.batches {
					batch := &all__Spinner_Component.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Spinner_Component) {
								destroy__Spinner_Component(comp);
							}
							pool_return(&all__Spinner_Component, comp);
							break pool_loop__Spinner_Component;
						}
					}
				}
			}
			case Component_Type.Terrain_Component: {
				pool_loop__Terrain_Component:
				for _, batch_idx in &all__Terrain_Component.batches {
					batch := &all__Terrain_Component.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Terrain_Component) {
								destroy__Terrain_Component(comp);
							}
							pool_return(&all__Terrain_Component, comp);
							break pool_loop__Terrain_Component;
						}
					}
				}
			}
			case Component_Type.Mesh_Renderer: {
				pool_loop__Mesh_Renderer:
				for _, batch_idx in &all__Mesh_Renderer.batches {
					batch := &all__Mesh_Renderer.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Mesh_Renderer) {
								destroy__Mesh_Renderer(comp);
							}
							pool_return(&all__Mesh_Renderer, comp);
							break pool_loop__Mesh_Renderer;
						}
					}
				}
			}
			case Component_Type.Box_Collider: {
				pool_loop__Box_Collider:
				for _, batch_idx in &all__Box_Collider.batches {
					batch := &all__Box_Collider.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Box_Collider) {
								destroy__Box_Collider(comp);
							}
							pool_return(&all__Box_Collider, comp);
							break pool_loop__Box_Collider;
						}
					}
				}
			}
			case Component_Type.Unit_Component: {
				pool_loop__Unit_Component:
				for _, batch_idx in &all__Unit_Component.batches {
					batch := &all__Unit_Component.batches[batch_idx];
					for _, idx in batch.list do if batch.empties[idx] {
						comp := &batch.list[idx];
						if comp.entity == entity_id {
							when #defined(destroy__Unit_Component) {
								destroy__Unit_Component(comp);
							}
							pool_return(&all__Unit_Component, comp);
							break pool_loop__Unit_Component;
						}
					}
				}
			}
			}
		}
		clear(&entity.component_types);
		append(&available_component_lists, entity.component_types);
		delete_key(&all_entities, entity_id);
	}
	clear(&entities_to_destroy);
}

update_inspector_window :: proc() {
	if imgui.begin("Scene") {
		for entity, entity_data in all_entities {
			if imgui.collapsing_header(tprint((entity_data.name == "" ? "<no_name>" : entity_data.name), " #", entity)) {
				for comp_type in entity_data.component_types {
					imgui.indent();
						switch comp_type {
						case Component_Type.Transform: {
							pool_loop__Transform:
							for _, batch_idx in &all__Transform.batches {
								batch := &all__Transform.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Transform"));
										break pool_loop__Transform;
									}
								}
							}
							break;
						}
						case Component_Type.Sprite_Renderer: {
							pool_loop__Sprite_Renderer:
							for _, batch_idx in &all__Sprite_Renderer.batches {
								batch := &all__Sprite_Renderer.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Sprite_Renderer"));
										break pool_loop__Sprite_Renderer;
									}
								}
							}
							break;
						}
						case Component_Type.Spinner_Component: {
							pool_loop__Spinner_Component:
							for _, batch_idx in &all__Spinner_Component.batches {
								batch := &all__Spinner_Component.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Spinner_Component"));
										break pool_loop__Spinner_Component;
									}
								}
							}
							break;
						}
						case Component_Type.Terrain_Component: {
							pool_loop__Terrain_Component:
							for _, batch_idx in &all__Terrain_Component.batches {
								batch := &all__Terrain_Component.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Terrain_Component"));
										break pool_loop__Terrain_Component;
									}
								}
							}
							break;
						}
						case Component_Type.Mesh_Renderer: {
							pool_loop__Mesh_Renderer:
							for _, batch_idx in &all__Mesh_Renderer.batches {
								batch := &all__Mesh_Renderer.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Mesh_Renderer"));
										break pool_loop__Mesh_Renderer;
									}
								}
							}
							break;
						}
						case Component_Type.Box_Collider: {
							pool_loop__Box_Collider:
							for _, batch_idx in &all__Box_Collider.batches {
								batch := &all__Box_Collider.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Box_Collider"));
										break pool_loop__Box_Collider;
									}
								}
							}
							break;
						}
						case Component_Type.Unit_Component: {
							pool_loop__Unit_Component:
							for _, batch_idx in &all__Unit_Component.batches {
								batch := &all__Unit_Component.batches[batch_idx];
								for _, idx in batch.list do if batch.empties[idx] {
									comp := &batch.list[idx];
									if comp.entity == entity {
										wb.imgui_struct(comp, tprint("Unit_Component"));
										break pool_loop__Unit_Component;
									}
								}
							}
							break;
						}
					}
					imgui.unindent();
				}
			}
		}
	}
	imgui.end();
}

