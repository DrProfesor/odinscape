package main

using import "core:fmt"
using import "core:strings"
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
	Player_Component,
	Unit_Component,
	Health_Component,
	Attack_Default_Command,
}

all__Transform: Pool(Transform, 64);
all__Sprite_Renderer: Pool(Sprite_Renderer, 64);
all__Spinner_Component: Pool(Spinner_Component, 64);
all__Terrain_Component: Pool(Terrain_Component, 64);
all__Mesh_Renderer: Pool(Mesh_Renderer, 64);
all__Box_Collider: Pool(Box_Collider, 64);
all__Player_Component: Pool(Player_Component, 64);
all__Unit_Component: Pool(Unit_Component, 64);
all__Health_Component: Pool(Health_Component, 64);
all__Attack_Default_Command: Pool(Attack_Default_Command, 64);

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
	when Type == Player_Component {
		t := pool_get(&all__Player_Component);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Player_Component);
		when #defined(init__Player_Component) {
			init__Player_Component(t);
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
	when Type == Health_Component {
		t := pool_get(&all__Health_Component);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Health_Component);
		when #defined(init__Health_Component) {
			init__Health_Component(t);
		}
		return t;
	}
	when Type == Attack_Default_Command {
		t := pool_get(&all__Attack_Default_Command);
		t.entity = entity;
		append(&entity_data.component_types, Component_Type.Attack_Default_Command);
		when #defined(init__Attack_Default_Command) {
			init__Attack_Default_Command(t);
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
	when Type == Player_Component {
		t := pool_get(&all__Player_Component);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Player_Component);
		when #defined(init__Player_Component) {
			init__Player_Component(t);
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
	when Type == Health_Component {
		t := pool_get(&all__Health_Component);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Health_Component);
		when #defined(init__Health_Component) {
			init__Health_Component(t);
		}
		return t;
	}
	when Type == Attack_Default_Command {
		t := pool_get(&all__Attack_Default_Command);
		t^ = component;
		append(&entity_data.component_types, Component_Type.Attack_Default_Command);
		when #defined(init__Attack_Default_Command) {
			init__Attack_Default_Command(t);
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
	when Type == Player_Component {
		for _, batch_idx in &all__Player_Component.batches {
			batch := &all__Player_Component.batches[batch_idx];
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
	when Type == Health_Component {
		for _, batch_idx in &all__Health_Component.batches {
			batch := &all__Health_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				if c.entity == entity do return c;
			}
		}
		return nil;
	}
	when Type == Attack_Default_Command {
		for _, batch_idx in &all__Attack_Default_Command.batches {
			batch := &all__Attack_Default_Command.batches[batch_idx];
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
	when #defined(update__Player_Component) {
		for _, batch_idx in &all__Player_Component.batches {
			batch := &all__Player_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Player_Component(c);
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
	when #defined(update__Health_Component) {
		for _, batch_idx in &all__Health_Component.batches {
			batch := &all__Health_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Health_Component(c);
			}
		}
	}
	when #defined(update__Attack_Default_Command) {
		for _, batch_idx in &all__Attack_Default_Command.batches {
			batch := &all__Attack_Default_Command.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				update__Attack_Default_Command(c);
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
	when #defined(render__Player_Component) {
		for _, batch_idx in &all__Player_Component.batches {
			batch := &all__Player_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Player_Component(c);
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
	when #defined(render__Health_Component) {
		for _, batch_idx in &all__Health_Component.batches {
			batch := &all__Health_Component.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Health_Component(c);
			}
		}
	}
	when #defined(render__Attack_Default_Command) {
		for _, batch_idx in &all__Attack_Default_Command.batches {
			batch := &all__Attack_Default_Command.batches[batch_idx];
			for _, idx in batch.list do if batch.empties[idx] {
				c := &batch.list[idx];
				render__Attack_Default_Command(c);
			}
		}
	}
}

serialize_entity_components :: proc(entity: Entity) -> string {
	serialized : Builder;
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
	Player_Component_comp := get_component(entity, Player_Component);
	if Player_Component_comp != nil {
		s := wbml.serialize(Player_Component_comp);
		sbprint(&serialized, "Player_Component\n");
		sbprint(&serialized, s);
	}
	Unit_Component_comp := get_component(entity, Unit_Component);
	if Unit_Component_comp != nil {
		s := wbml.serialize(Unit_Component_comp);
		sbprint(&serialized, "Unit_Component\n");
		sbprint(&serialized, s);
	}
	Health_Component_comp := get_component(entity, Health_Component);
	if Health_Component_comp != nil {
		s := wbml.serialize(Health_Component_comp);
		sbprint(&serialized, "Health_Component\n");
		sbprint(&serialized, s);
	}
	Attack_Default_Command_comp := get_component(entity, Attack_Default_Command);
	if Attack_Default_Command_comp != nil {
		s := wbml.serialize(Attack_Default_Command_comp);
		sbprint(&serialized, "Attack_Default_Command\n");
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
	when #defined(init__Player_Component) {
		Player_Component_comp := get_component(entity, Player_Component);
		if Player_Component_comp != nil {
			init__Player_Component(Player_Component_comp);
		}
	}
	when #defined(init__Unit_Component) {
		Unit_Component_comp := get_component(entity, Unit_Component);
		if Unit_Component_comp != nil {
			init__Unit_Component(Unit_Component_comp);
		}
	}
	when #defined(init__Health_Component) {
		Health_Component_comp := get_component(entity, Health_Component);
		if Health_Component_comp != nil {
			init__Health_Component(Health_Component_comp);
		}
	}
	when #defined(init__Attack_Default_Command) {
		Attack_Default_Command_comp := get_component(entity, Attack_Default_Command);
		if Attack_Default_Command_comp != nil {
			init__Attack_Default_Command(Attack_Default_Command_comp);
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
			case "Player_Component": {
				component := wbml.deserialize(Player_Component, component_data);
				add_component(entity, component);
			}
			case "Unit_Component": {
				component := wbml.deserialize(Unit_Component, component_data);
				add_component(entity, component);
			}
			case "Health_Component": {
				component := wbml.deserialize(Health_Component, component_data);
				add_component(entity, component);
			}
			case "Attack_Default_Command": {
				component := wbml.deserialize(Attack_Default_Command, component_data);
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
				comp := get_component(entity_id, Transform);
				assert(comp != nil);
				when #defined(destroy__Transform) {
					destroy__Transform(comp);
				}
				pool_return(&all__Transform, comp);
			}
			case Component_Type.Sprite_Renderer: {
				comp := get_component(entity_id, Sprite_Renderer);
				assert(comp != nil);
				when #defined(destroy__Sprite_Renderer) {
					destroy__Sprite_Renderer(comp);
				}
				pool_return(&all__Sprite_Renderer, comp);
			}
			case Component_Type.Spinner_Component: {
				comp := get_component(entity_id, Spinner_Component);
				assert(comp != nil);
				when #defined(destroy__Spinner_Component) {
					destroy__Spinner_Component(comp);
				}
				pool_return(&all__Spinner_Component, comp);
			}
			case Component_Type.Terrain_Component: {
				comp := get_component(entity_id, Terrain_Component);
				assert(comp != nil);
				when #defined(destroy__Terrain_Component) {
					destroy__Terrain_Component(comp);
				}
				pool_return(&all__Terrain_Component, comp);
			}
			case Component_Type.Mesh_Renderer: {
				comp := get_component(entity_id, Mesh_Renderer);
				assert(comp != nil);
				when #defined(destroy__Mesh_Renderer) {
					destroy__Mesh_Renderer(comp);
				}
				pool_return(&all__Mesh_Renderer, comp);
			}
			case Component_Type.Box_Collider: {
				comp := get_component(entity_id, Box_Collider);
				assert(comp != nil);
				when #defined(destroy__Box_Collider) {
					destroy__Box_Collider(comp);
				}
				pool_return(&all__Box_Collider, comp);
			}
			case Component_Type.Player_Component: {
				comp := get_component(entity_id, Player_Component);
				assert(comp != nil);
				when #defined(destroy__Player_Component) {
					destroy__Player_Component(comp);
				}
				pool_return(&all__Player_Component, comp);
			}
			case Component_Type.Unit_Component: {
				comp := get_component(entity_id, Unit_Component);
				assert(comp != nil);
				when #defined(destroy__Unit_Component) {
					destroy__Unit_Component(comp);
				}
				pool_return(&all__Unit_Component, comp);
			}
			case Component_Type.Health_Component: {
				comp := get_component(entity_id, Health_Component);
				assert(comp != nil);
				when #defined(destroy__Health_Component) {
					destroy__Health_Component(comp);
				}
				pool_return(&all__Health_Component, comp);
			}
			case Component_Type.Attack_Default_Command: {
				comp := get_component(entity_id, Attack_Default_Command);
				assert(comp != nil);
				when #defined(destroy__Attack_Default_Command) {
					destroy__Attack_Default_Command(comp);
				}
				pool_return(&all__Attack_Default_Command, comp);
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
			name := tprint((entity_data.name == "" ? "<no_name>" : entity_data.name), " #", entity);
			imgui.push_id(name);
			defer imgui.pop_id();
			if imgui.collapsing_header(name) {
				for comp_type in entity_data.component_types {
					imgui.indent();
						switch comp_type {
						case Component_Type.Transform: {
							comp := get_component(entity, Transform);
							assert(comp != nil);
							wb.imgui_struct(comp, "Transform");
						}
						case Component_Type.Sprite_Renderer: {
							comp := get_component(entity, Sprite_Renderer);
							assert(comp != nil);
							wb.imgui_struct(comp, "Sprite_Renderer");
						}
						case Component_Type.Spinner_Component: {
							comp := get_component(entity, Spinner_Component);
							assert(comp != nil);
							wb.imgui_struct(comp, "Spinner_Component");
						}
						case Component_Type.Terrain_Component: {
							comp := get_component(entity, Terrain_Component);
							assert(comp != nil);
							wb.imgui_struct(comp, "Terrain_Component");
						}
						case Component_Type.Mesh_Renderer: {
							comp := get_component(entity, Mesh_Renderer);
							assert(comp != nil);
							wb.imgui_struct(comp, "Mesh_Renderer");
						}
						case Component_Type.Box_Collider: {
							comp := get_component(entity, Box_Collider);
							assert(comp != nil);
							wb.imgui_struct(comp, "Box_Collider");
						}
						case Component_Type.Player_Component: {
							comp := get_component(entity, Player_Component);
							assert(comp != nil);
							wb.imgui_struct(comp, "Player_Component");
						}
						case Component_Type.Unit_Component: {
							comp := get_component(entity, Unit_Component);
							assert(comp != nil);
							wb.imgui_struct(comp, "Unit_Component");
						}
						case Component_Type.Health_Component: {
							comp := get_component(entity, Health_Component);
							assert(comp != nil);
							wb.imgui_struct(comp, "Health_Component");
						}
						case Component_Type.Attack_Default_Command: {
							comp := get_component(entity, Attack_Default_Command);
							assert(comp != nil);
							wb.imgui_struct(comp, "Attack_Default_Command");
						}
					}
				imgui.unindent();
			}
		}
	}
}
imgui.end();
}

