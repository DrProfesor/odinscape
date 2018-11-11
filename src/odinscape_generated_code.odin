package main

using import "core:fmt"
      import wb "shared:workbench"

Component_Type :: enum {
	Transform,
	Sprite_Renderer,
	Spinner_Component,
	Mesh_Renderer,
}

all_Transform: [dynamic]Transform;
all_Sprite_Renderer: [dynamic]Sprite_Renderer;
all_Spinner_Component: [dynamic]Spinner_Component;
all_Mesh_Renderer: [dynamic]Mesh_Renderer;

add_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	entity_data, ok := all_entities[entity]; assert(ok);
	defer all_entities[entity] = entity_data;
	_t: Type; _t.entity = entity;
	when Type == Transform {
		append(&all_Transform, _t);
		t := &all_Transform[len(all_Transform)-1];
		append(&entity_data.component_types, Component_Type.Transform);
		return t;
	}
	when Type == Sprite_Renderer {
		append(&all_Sprite_Renderer, _t);
		t := &all_Sprite_Renderer[len(all_Sprite_Renderer)-1];
		append(&entity_data.component_types, Component_Type.Sprite_Renderer);
		return t;
	}
	when Type == Spinner_Component {
		append(&all_Spinner_Component, _t);
		t := &all_Spinner_Component[len(all_Spinner_Component)-1];
		append(&entity_data.component_types, Component_Type.Spinner_Component);
		init_spinner(t);
		return t;
	}
	when Type == Mesh_Renderer {
		append(&all_Mesh_Renderer, _t);
		t := &all_Mesh_Renderer[len(all_Mesh_Renderer)-1];
		append(&entity_data.component_types, Component_Type.Mesh_Renderer);
		return t;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml")); return nil;
}

get_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	when Type == Transform {
		for _, i in all_Transform {
			c := &all_Transform[i]; if c.entity == entity do return c;
		}
	}
	when Type == Sprite_Renderer {
		for _, i in all_Sprite_Renderer {
			c := &all_Sprite_Renderer[i]; if c.entity == entity do return c;
		}
	}
	when Type == Spinner_Component {
		for _, i in all_Spinner_Component {
			c := &all_Spinner_Component[i]; if c.entity == entity do return c;
		}
	}
	when Type == Mesh_Renderer {
		for _, i in all_Mesh_Renderer {
			c := &all_Mesh_Renderer[i]; if c.entity == entity do return c;
		}
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml")); return nil;
}

call_component_updates :: proc() {
	for _, i in all_Spinner_Component {
		c := &all_Spinner_Component[i]; update_spinner(c);
	}
}

call_component_renders :: proc() {
	for _, i in all_Sprite_Renderer {
		c := &all_Sprite_Renderer[i]; render_sprite_renderer(c);
	}
	for _, i in all_Mesh_Renderer {
		c := &all_Mesh_Renderer[i]; render_mesh_renderer(c);
	}
}

destroy_marked_entities :: proc() {
	for entity_id in entities_to_destroy {
		entity, ok := all_entities[entity_id]; assert(ok);
		for comp_type in entity.component_types {
			switch comp_type {
			case Component_Type.Transform:
				for _, i in all_Transform {
					comp := &all_Transform[i];
					if comp.entity == entity_id {
						unordered_remove(&all_Transform, i);
						break;
					}
				}

			case Component_Type.Sprite_Renderer:
				for _, i in all_Sprite_Renderer {
					comp := &all_Sprite_Renderer[i];
					if comp.entity == entity_id {
						unordered_remove(&all_Sprite_Renderer, i);
						break;
					}
				}

			case Component_Type.Spinner_Component:
				for _, i in all_Spinner_Component {
					comp := &all_Spinner_Component[i];
					if comp.entity == entity_id {
						unordered_remove(&all_Spinner_Component, i);
						break;
					}
				}

			case Component_Type.Mesh_Renderer:
				for _, i in all_Mesh_Renderer {
					comp := &all_Mesh_Renderer[i];
					if comp.entity == entity_id {
						destroy_mesh_renderer(comp);
						unordered_remove(&all_Mesh_Renderer, i);
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

