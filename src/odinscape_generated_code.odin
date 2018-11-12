package main

using import "core:fmt"
      import wb "shared:workbench"

Component_Type :: enum {
	Transform,
	Sprite_Renderer,
	Spinner_Component,
	Mesh_Renderer,
}

all__Transform: [dynamic]Transform;
all__Sprite_Renderer: [dynamic]Sprite_Renderer;
all__Spinner_Component: [dynamic]Spinner_Component;
all__Mesh_Renderer: [dynamic]Mesh_Renderer;

add_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	entity_data, ok := all_entities[entity]; assert(ok);
	defer all_entities[entity] = entity_data;
	_t: Type; _t.entity = entity;
	when Type == Transform {
		append(&all__Transform, _t);
		t := &all__Transform[len(all__Transform)-1];
		append(&entity_data.component_types, Component_Type.Transform);
		when #defined(init__Transform) {
			for _, i in all__Transform {
				c := &all__Transform[i];
				init__Transform(c);
			}
		}
		return t;
	}
	when Type == Sprite_Renderer {
		append(&all__Sprite_Renderer, _t);
		t := &all__Sprite_Renderer[len(all__Sprite_Renderer)-1];
		append(&entity_data.component_types, Component_Type.Sprite_Renderer);
		when #defined(init__Sprite_Renderer) {
			for _, i in all__Sprite_Renderer {
				c := &all__Sprite_Renderer[i];
				init__Sprite_Renderer(c);
			}
		}
		return t;
	}
	when Type == Spinner_Component {
		append(&all__Spinner_Component, _t);
		t := &all__Spinner_Component[len(all__Spinner_Component)-1];
		append(&entity_data.component_types, Component_Type.Spinner_Component);
		when #defined(init__Spinner_Component) {
			for _, i in all__Spinner_Component {
				c := &all__Spinner_Component[i];
				init__Spinner_Component(c);
			}
		}
		return t;
	}
	when Type == Mesh_Renderer {
		append(&all__Mesh_Renderer, _t);
		t := &all__Mesh_Renderer[len(all__Mesh_Renderer)-1];
		append(&entity_data.component_types, Component_Type.Mesh_Renderer);
		when #defined(init__Mesh_Renderer) {
			for _, i in all__Mesh_Renderer {
				c := &all__Mesh_Renderer[i];
				init__Mesh_Renderer(c);
			}
		}
		return t;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml")); return nil;
}

get_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	when Type == Transform {
		for _, i in all__Transform {
			c := &all__Transform[i]; if c.entity == entity do return c;
		}
	}
	when Type == Sprite_Renderer {
		for _, i in all__Sprite_Renderer {
			c := &all__Sprite_Renderer[i]; if c.entity == entity do return c;
		}
	}
	when Type == Spinner_Component {
		for _, i in all__Spinner_Component {
			c := &all__Spinner_Component[i]; if c.entity == entity do return c;
		}
	}
	when Type == Mesh_Renderer {
		for _, i in all__Mesh_Renderer {
			c := &all__Mesh_Renderer[i]; if c.entity == entity do return c;
		}
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml")); return nil;
}

call_component_updates :: proc() {
	when #defined(update__Transform) {
		for _, i in all__Transform {
			c := &all__Transform[i];
			update__Transform(c);
		}
	}
	when #defined(update__Sprite_Renderer) {
		for _, i in all__Sprite_Renderer {
			c := &all__Sprite_Renderer[i];
			update__Sprite_Renderer(c);
		}
	}
	when #defined(update__Spinner_Component) {
		for _, i in all__Spinner_Component {
			c := &all__Spinner_Component[i];
			update__Spinner_Component(c);
		}
	}
	when #defined(update__Mesh_Renderer) {
		for _, i in all__Mesh_Renderer {
			c := &all__Mesh_Renderer[i];
			update__Mesh_Renderer(c);
		}
	}
}

call_component_renders :: proc() {
	when #defined(render__Transform) {
		for _, i in all__Transform {
			c := &all__Transform[i];
			render__Transform(c);
		}
	}
	when #defined(render__Sprite_Renderer) {
		for _, i in all__Sprite_Renderer {
			c := &all__Sprite_Renderer[i];
			render__Sprite_Renderer(c);
		}
	}
	when #defined(render__Spinner_Component) {
		for _, i in all__Spinner_Component {
			c := &all__Spinner_Component[i];
			render__Spinner_Component(c);
		}
	}
	when #defined(render__Mesh_Renderer) {
		for _, i in all__Mesh_Renderer {
			c := &all__Mesh_Renderer[i];
			render__Mesh_Renderer(c);
		}
	}
}

destroy_marked_entities :: proc() {
	for entity_id in entities_to_destroy {
		entity, ok := all_entities[entity_id]; assert(ok);
		for comp_type in entity.component_types {
			switch comp_type {
			case Component_Type.Transform:
				for _, i in all__Transform {
					comp := &all__Transform[i];
					if comp.entity == entity_id {
						when #defined(destroy__Transform) {
							for _, i in all__Transform {
								c := &all__Transform[i];
								destroy__Transform(c);
							}
						}
						unordered_remove(&all__Transform, i);
						break;
					}
				}
			
			case Component_Type.Sprite_Renderer:
				for _, i in all__Sprite_Renderer {
					comp := &all__Sprite_Renderer[i];
					if comp.entity == entity_id {
						when #defined(destroy__Sprite_Renderer) {
							for _, i in all__Sprite_Renderer {
								c := &all__Sprite_Renderer[i];
								destroy__Sprite_Renderer(c);
							}
						}
						unordered_remove(&all__Sprite_Renderer, i);
						break;
					}
				}
			
			case Component_Type.Spinner_Component:
				for _, i in all__Spinner_Component {
					comp := &all__Spinner_Component[i];
					if comp.entity == entity_id {
						when #defined(destroy__Spinner_Component) {
							for _, i in all__Spinner_Component {
								c := &all__Spinner_Component[i];
								destroy__Spinner_Component(c);
							}
						}
						unordered_remove(&all__Spinner_Component, i);
						break;
					}
				}
			
			case Component_Type.Mesh_Renderer:
				for _, i in all__Mesh_Renderer {
					comp := &all__Mesh_Renderer[i];
					if comp.entity == entity_id {
						when #defined(destroy__Mesh_Renderer) {
							for _, i in all__Mesh_Renderer {
								c := &all__Mesh_Renderer[i];
								destroy__Mesh_Renderer(c);
							}
						}
						unordered_remove(&all__Mesh_Renderer, i);
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

