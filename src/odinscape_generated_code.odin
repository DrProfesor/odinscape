package main

using import "core:fmt"
      import wb "shared:workbench"

Component_Type :: enum {
	Sprite_Renderer,
	Mesh_Renderer,
	Texture_Component,
	Unit_Component,
	Spinner_Component,
	Transform,
	Box_Collider,
}

all__Sprite_Renderer: [dynamic]Sprite_Renderer;
all__Mesh_Renderer: [dynamic]Mesh_Renderer;
all__Texture_Component: [dynamic]Texture_Component;
all__Unit_Component: [dynamic]Unit_Component;
all__Spinner_Component: [dynamic]Spinner_Component;
all__Transform: [dynamic]Transform;
all__Box_Collider: [dynamic]Box_Collider;

add_component :: proc[add_component_type, add_component_value];

add_component_type :: proc(entity: Entity, $Type: typeid) -> ^Type {
	entity_data, ok := all_entities[entity]; assert(ok);
	defer all_entities[entity] = entity_data;
	_t: Type; _t.entity = entity;
	when Type == Sprite_Renderer {
		new_length := append(&all__Sprite_Renderer, _t);
		t := &all__Sprite_Renderer[new_length-1];
		append(&entity_data.component_types, Component_Type.Sprite_Renderer);
		when #defined(init__Sprite_Renderer) {
			init__Sprite_Renderer(t);
		}
		return t;
	}
	when Type == Mesh_Renderer {
		new_length := append(&all__Mesh_Renderer, _t);
		t := &all__Mesh_Renderer[new_length-1];
		append(&entity_data.component_types, Component_Type.Mesh_Renderer);
		when #defined(init__Mesh_Renderer) {
			init__Mesh_Renderer(t);
		}
		return t;
	}
	when Type == Texture_Component {
		new_length := append(&all__Texture_Component, _t);
		t := &all__Texture_Component[new_length-1];
		append(&entity_data.component_types, Component_Type.Texture_Component);
		when #defined(init__Texture_Component) {
			init__Texture_Component(t);
		}
		return t;
	}
	when Type == Unit_Component {
		new_length := append(&all__Unit_Component, _t);
		t := &all__Unit_Component[new_length-1];
		append(&entity_data.component_types, Component_Type.Unit_Component);
		when #defined(init__Unit_Component) {
			init__Unit_Component(t);
		}
		return t;
	}
	when Type == Spinner_Component {
		new_length := append(&all__Spinner_Component, _t);
		t := &all__Spinner_Component[new_length-1];
		append(&entity_data.component_types, Component_Type.Spinner_Component);
		when #defined(init__Spinner_Component) {
			init__Spinner_Component(t);
		}
		return t;
	}
	when Type == Transform {
		new_length := append(&all__Transform, _t);
		t := &all__Transform[new_length-1];
		append(&entity_data.component_types, Component_Type.Transform);
		when #defined(init__Transform) {
			init__Transform(t);
		}
		return t;
	}
	when Type == Box_Collider {
		new_length := append(&all__Box_Collider, _t);
		t := &all__Box_Collider[new_length-1];
		append(&entity_data.component_types, Component_Type.Box_Collider);
		when #defined(init__Box_Collider) {
			init__Box_Collider(t);
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
	when Type == Sprite_Renderer {
		new_length := append(&all__Sprite_Renderer, component);
		t := &all__Sprite_Renderer[new_length-1];
		append(&entity_data.component_types, Component_Type.Sprite_Renderer);
		when #defined(init__Sprite_Renderer) {
			init__Sprite_Renderer(t);
		}
		return t;
	}
	when Type == Mesh_Renderer {
		new_length := append(&all__Mesh_Renderer, component);
		t := &all__Mesh_Renderer[new_length-1];
		append(&entity_data.component_types, Component_Type.Mesh_Renderer);
		when #defined(init__Mesh_Renderer) {
			init__Mesh_Renderer(t);
		}
		return t;
	}
	when Type == Texture_Component {
		new_length := append(&all__Texture_Component, component);
		t := &all__Texture_Component[new_length-1];
		append(&entity_data.component_types, Component_Type.Texture_Component);
		when #defined(init__Texture_Component) {
			init__Texture_Component(t);
		}
		return t;
	}
	when Type == Unit_Component {
		new_length := append(&all__Unit_Component, component);
		t := &all__Unit_Component[new_length-1];
		append(&entity_data.component_types, Component_Type.Unit_Component);
		when #defined(init__Unit_Component) {
			init__Unit_Component(t);
		}
		return t;
	}
	when Type == Spinner_Component {
		new_length := append(&all__Spinner_Component, component);
		t := &all__Spinner_Component[new_length-1];
		append(&entity_data.component_types, Component_Type.Spinner_Component);
		when #defined(init__Spinner_Component) {
			init__Spinner_Component(t);
		}
		return t;
	}
	when Type == Transform {
		new_length := append(&all__Transform, component);
		t := &all__Transform[new_length-1];
		append(&entity_data.component_types, Component_Type.Transform);
		when #defined(init__Transform) {
			init__Transform(t);
		}
		return t;
	}
	when Type == Box_Collider {
		new_length := append(&all__Box_Collider, component);
		t := &all__Box_Collider[new_length-1];
		append(&entity_data.component_types, Component_Type.Box_Collider);
		when #defined(init__Box_Collider) {
			init__Box_Collider(t);
		}
		return t;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml"));
	return nil;
}

get_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	when Type == Sprite_Renderer {
		for _, i in all__Sprite_Renderer {
			c := &all__Sprite_Renderer[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	when Type == Mesh_Renderer {
		for _, i in all__Mesh_Renderer {
			c := &all__Mesh_Renderer[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	when Type == Texture_Component {
		for _, i in all__Texture_Component {
			c := &all__Texture_Component[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	when Type == Unit_Component {
		for _, i in all__Unit_Component {
			c := &all__Unit_Component[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	when Type == Spinner_Component {
		for _, i in all__Spinner_Component {
			c := &all__Spinner_Component[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	when Type == Transform {
		for _, i in all__Transform {
			c := &all__Transform[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	when Type == Box_Collider {
		for _, i in all__Box_Collider {
			c := &all__Box_Collider[i];
			if c.entity == entity do return c;
		}
		return nil;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml"));
	return nil;
}

call_component_updates :: proc() {
	when #defined(update__Sprite_Renderer) {
		for _, i in all__Sprite_Renderer {
			c := &all__Sprite_Renderer[i];
			update__Sprite_Renderer(c);
		}
	}
	when #defined(update__Mesh_Renderer) {
		for _, i in all__Mesh_Renderer {
			c := &all__Mesh_Renderer[i];
			update__Mesh_Renderer(c);
		}
	}
	when #defined(update__Texture_Component) {
		for _, i in all__Texture_Component {
			c := &all__Texture_Component[i];
			update__Texture_Component(c);
		}
	}
	when #defined(update__Unit_Component) {
		for _, i in all__Unit_Component {
			c := &all__Unit_Component[i];
			update__Unit_Component(c);
		}
	}
	when #defined(update__Spinner_Component) {
		for _, i in all__Spinner_Component {
			c := &all__Spinner_Component[i];
			update__Spinner_Component(c);
		}
	}
	when #defined(update__Transform) {
		for _, i in all__Transform {
			c := &all__Transform[i];
			update__Transform(c);
		}
	}
	when #defined(update__Box_Collider) {
		for _, i in all__Box_Collider {
			c := &all__Box_Collider[i];
			update__Box_Collider(c);
		}
	}
}

call_component_renders :: proc() {
	when #defined(render__Sprite_Renderer) {
		for _, i in all__Sprite_Renderer {
			c := &all__Sprite_Renderer[i];
			render__Sprite_Renderer(c);
		}
	}
	when #defined(render__Mesh_Renderer) {
		for _, i in all__Mesh_Renderer {
			c := &all__Mesh_Renderer[i];
			render__Mesh_Renderer(c);
		}
	}
	when #defined(render__Texture_Component) {
		for _, i in all__Texture_Component {
			c := &all__Texture_Component[i];
			render__Texture_Component(c);
		}
	}
	when #defined(render__Unit_Component) {
		for _, i in all__Unit_Component {
			c := &all__Unit_Component[i];
			render__Unit_Component(c);
		}
	}
	when #defined(render__Spinner_Component) {
		for _, i in all__Spinner_Component {
			c := &all__Spinner_Component[i];
			render__Spinner_Component(c);
		}
	}
	when #defined(render__Transform) {
		for _, i in all__Transform {
			c := &all__Transform[i];
			render__Transform(c);
		}
	}
	when #defined(render__Box_Collider) {
		for _, i in all__Box_Collider {
			c := &all__Box_Collider[i];
			render__Box_Collider(c);
		}
	}
}

destroy_marked_entities :: proc() {
	for entity_id in entities_to_destroy {
		entity, ok := all_entities[entity_id]; assert(ok);
		for comp_type in entity.component_types {
			switch comp_type {
			case Component_Type.Sprite_Renderer:
				for _, i in all__Sprite_Renderer {
					comp := &all__Sprite_Renderer[i];
					if comp.entity == entity_id {
						when #defined(destroy__Sprite_Renderer) {
							destroy__Sprite_Renderer(comp);
						}
						unordered_remove(&all__Sprite_Renderer, i);
						break;
					}
				}
			
			case Component_Type.Mesh_Renderer:
				for _, i in all__Mesh_Renderer {
					comp := &all__Mesh_Renderer[i];
					if comp.entity == entity_id {
						when #defined(destroy__Mesh_Renderer) {
							destroy__Mesh_Renderer(comp);
						}
						unordered_remove(&all__Mesh_Renderer, i);
						break;
					}
				}
			
			case Component_Type.Texture_Component:
				for _, i in all__Texture_Component {
					comp := &all__Texture_Component[i];
					if comp.entity == entity_id {
						when #defined(destroy__Texture_Component) {
							destroy__Texture_Component(comp);
						}
						unordered_remove(&all__Texture_Component, i);
						break;
					}
				}
			
			case Component_Type.Unit_Component:
				for _, i in all__Unit_Component {
					comp := &all__Unit_Component[i];
					if comp.entity == entity_id {
						when #defined(destroy__Unit_Component) {
							destroy__Unit_Component(comp);
						}
						unordered_remove(&all__Unit_Component, i);
						break;
					}
				}
			
			case Component_Type.Spinner_Component:
				for _, i in all__Spinner_Component {
					comp := &all__Spinner_Component[i];
					if comp.entity == entity_id {
						when #defined(destroy__Spinner_Component) {
							destroy__Spinner_Component(comp);
						}
						unordered_remove(&all__Spinner_Component, i);
						break;
					}
				}
			
			case Component_Type.Transform:
				for _, i in all__Transform {
					comp := &all__Transform[i];
					if comp.entity == entity_id {
						when #defined(destroy__Transform) {
							destroy__Transform(comp);
						}
						unordered_remove(&all__Transform, i);
						break;
					}
				}
			
			case Component_Type.Box_Collider:
				for _, i in all__Box_Collider {
					comp := &all__Box_Collider[i];
					if comp.entity == entity_id {
						when #defined(destroy__Box_Collider) {
							destroy__Box_Collider(comp);
						}
						unordered_remove(&all__Box_Collider, i);
						break;
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

