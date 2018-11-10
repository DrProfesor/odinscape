package main

using import "core:fmt"

Component_Type :: union {
	Transform,
	Sprite_Renderer,
	Spinner_Component,
	Mesh_Renderer,
}

add_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	when Type == Transform {
		_t: Type; _t.entity = entity;
		append(&all_transforms, _t);
		t := &all_transforms[len(all_transforms)-1];
		return t;
	}
	when Type == Sprite_Renderer {
		_t: Type; _t.entity = entity;
		append(&all_sprite_renderers, _t);
		t := &all_sprite_renderers[len(all_sprite_renderers)-1];
		return t;
	}
	when Type == Spinner_Component {
		_t: Type; _t.entity = entity;
		append(&all_spinners, _t);
		t := &all_spinners[len(all_spinners)-1];
		init_spinner(t);
		return t;
	}
	when Type == Mesh_Renderer {
		_t: Type; _t.entity = entity;
		append(&all_mesh_renderers, _t);
		t := &all_mesh_renderers[len(all_mesh_renderers)-1];
		return t;
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml")); return nil;
}

get_component :: proc(entity: Entity, $Type: typeid) -> ^Type {
	when Type == Transform {
		for _, i in all_transforms {
			c := &all_transforms[i]; if c.entity == entity do return c;
		}
	}
	when Type == Sprite_Renderer {
		for _, i in all_sprite_renderers {
			c := &all_sprite_renderers[i]; if c.entity == entity do return c;
		}
	}
	when Type == Spinner_Component {
		for _, i in all_spinners {
			c := &all_spinners[i]; if c.entity == entity do return c;
		}
	}
	when Type == Mesh_Renderer {
		for _, i in all_mesh_renderers {
			c := &all_mesh_renderers[i]; if c.entity == entity do return c;
		}
	}
	panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml")); return nil;
}

destroy_component :: proc(component: $Type) {
}

call_component_updates :: proc() {
	for _, i in all_spinners {
		c := &all_spinners[i]; update_spinner(c);
	}
}

call_component_renders :: proc() {
	for _, i in all_sprite_renderers {
		c := &all_sprite_renderers[i]; render_sprite_renderer(c);
	}
	for _, i in all_mesh_renderers {
		c := &all_mesh_renderers[i]; render_mesh_renderer(c);
	}
}

call_component_destroys :: proc() {
}



