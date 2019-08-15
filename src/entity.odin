package main

using import "core:math"
using import "core:fmt"
import rt "core:runtime"
import "core:mem"
import "core:strings"
import "core:os"

import wb "shared:workbench"
import    "shared:workbench/wbml"
import    "shared:workbench/laas"
using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"
import    "shared:workbench/gpu"
import    "shared:workbench/reflection"
import    "shared:workbench/external/imgui"

Component_Base :: struct {
	e: Entity "imgui_hidden,wbml_unserialized",
	enabled: bool,
}

Transform :: struct {
	using base: Component_Base,
	position: Vec3,
	rotation: Quat,
	scale: Vec3,
}

em_add_component_type :: proc($Type: typeid, update_proc: proc(^Type, f32), render_proc: proc(^Type), init_proc: proc(^Type) = nil) {
	when DEVELOPER {
		t: Type;
		assert(&t.base == &t);
	}
    
	if component_types == nil {
		component_types = make(map[typeid]Component_Type, 1);
	}
	id := typeid_of(Type);
	assert(id notin component_types);
	component_types[id] = Component_Type{type_info_of(Type), transmute(mem.Raw_Dynamic_Array)make([dynamic]Type, 0, 1), make([dynamic]int, 0, 1), cast(proc(rawptr, f32))update_proc, cast(proc(rawptr))render_proc, cast(proc(rawptr))init_proc};
}

em_make_entity :: proc(name := "Entity", requested_id: Entity = 0) -> Entity {
	@static _last_entity_id: int;
	eid: Entity;
	if requested_id != 0 {
		eid = requested_id;
		_last_entity_id = max(_last_entity_id, requested_id);
	}
	else {
		_last_entity_id += 1;
		eid = _last_entity_id;
	}
    
	when DEVELOPER {
		for e in active_entities {
			assert(e != eid, tprint("Duplicate entity ID!!!: ", e));
		}
		_, ok := entity_data[eid];
		assert(!ok, tprint("Duplicate entity ID that the previous check should have caught!!!: ", eid));
	}
    
	append(&active_entities, eid);
	entity_data[eid] = Entity_Data{name, {}};
    
	tf := em_add_component(eid, Transform);
	tf.rotation = Quat{0, 0, 0, 1};
	tf.scale = Vec3{1, 1, 1};
    
	return eid;
}

em_destroy_entity :: proc(eid: Entity) {
	append(&entities_to_destroy, eid);
}

em_add_component :: proc(eid: Entity, $T: typeid) -> ^T { // note(josh): volatile return value, do not store
	ptr := _em_add_component_internal(eid, typeid_of(T));
	assert(ptr != nil);
	return cast(^T)ptr;
}

em_get_component :: proc(eid: Entity, $T: typeid, loc := #caller_location) -> ^T {
	ptr := _em_get_component_internal(eid, typeid_of(T));
	return cast(^T)ptr;
}

em_remove_component :: proc(eid: Entity, $T: typeid) -> bool {
	unimplemented();
	return {};
}

em_get_all_components :: proc($T: typeid) -> []T {
	data, ok := component_types[typeid_of(T)];
	assert(ok, tprint("Couldn't find component type: ", type_info_of(T)));
	da := transmute([dynamic]T)data.storage;
	return da[:];
}



em_update :: proc(dt: f32) {
	// destroy entities
	{
		for eid in entities_to_destroy {
			data, ok := entity_data[eid];
			assert(ok);
			defer delete_key(&entity_data, eid);
            
			for c in data.components {
				component_data, ok := component_types[c];
				assert(ok);
				defer component_types[c] = component_data;
                
				for i in 0..<component_data.storage.len {
					ptr := cast(^Component_Base)mem.ptr_offset(cast(^u8)component_data.storage.data, i * component_data.ti.size);
					if ptr.e == eid {
						append(&component_data.reusable_indices, i);
					}
					ptr.e = 0;
				}
			}
			delete(data.components); // todo(josh): @Alloc
            
            
            
			for active, active_idx in active_entities {
				if active == eid {
					unordered_remove(&active_entities, active_idx);
					break;
				}
			}
		}
        
        
		clear(&entities_to_destroy);
	}
    
	// update components
	{
		for tid, data in component_types {
			if data.update_proc != nil {
				for i in 0..<data.storage.len {
					ptr := mem.ptr_offset(cast(^u8)data.storage.data, i * data.ti.size);
					comp := cast(^Component_Base)ptr;
					if comp.enabled {
						data.update_proc(ptr, dt);
					}
				}
			}
		}
	}
}

em_render :: proc() {
	for tid, data in component_types {
		if data.render_proc != nil {
			for i in 0..<data.storage.len {
				ptr := mem.ptr_offset(cast(^u8)data.storage.data, i * data.ti.size);
				comp := cast(^Component_Base)ptr;
				if comp.enabled {
					data.render_proc(ptr);
				}
			}
		}
	}
}

em_get_storage :: proc($T: typeid) -> []T {
	component_data, ok := component_types[typeid_of(T)];
	assert(ok);
	return (transmute([dynamic]T)component_data.storage)[:];
}

_em_add_component_internal :: proc(eid: Entity, tid: typeid) -> rawptr {
	ti := type_info_of(tid);
    
	if already_exists := _em_get_component_internal(eid, tid); already_exists != nil {
		logln("Error: Cannot add more than one of the same component: ", ti);
		return nil;
	}
    
	data, ok := component_types[tid];
	assert(ok, tprint("Couldn't find component type: ", ti));
	defer component_types[tid] = data;
    
	ptr: rawptr;
	if len(data.reusable_indices) > 0 {
		i := pop(&data.reusable_indices);
		ptr = mem.ptr_offset(cast(^u8)data.storage.data, i * ti.size);
	}
	else {
		if data.storage.len >= data.storage.cap {
			new_cap := data.storage.cap * 2;
			new_data := mem.alloc(new_cap * ti.size);
			mem.copy(new_data, data.storage.data, data.storage.len * ti.size);
			free(data.storage.data);
			data.storage.data = new_data;
			data.storage.cap = new_cap;
		}
		data.storage.len += 1;
		ptr = mem.ptr_offset(cast(^u8)data.storage.data, ti.size * (data.storage.len-1));
	}
    
	base := cast(^Component_Base)ptr;
	base.e = eid;
	base.enabled = true;
    
	if data.init_proc != nil {
		data.init_proc(ptr);
	}
    
	e_data, ok2 := entity_data[eid];
	assert(ok2);
	append(&e_data.components, tid);
	entity_data[eid] = e_data;
    
	return ptr;
}

_em_get_component_internal :: proc(eid: Entity, tid: typeid) -> rawptr {
	ti := type_info_of(tid);
	data, ok := component_types[tid];
	assert(ok, tprint("Couldn't find component type: ", ti));
    
	for i in 0..<data.storage.len {
		ptr := cast(^Component_Base)mem.ptr_offset(cast(^u8)data.storage.data, i * ti.size);
		if ptr.e == eid {
			return ptr;
		}
	}
	return nil;
}




load_entity_from_wbml :: proc(entity_name: string, text: string) -> Entity {
	lexer := laas.make_lexer(text);
	eid_token, ok2 := laas.expect(&lexer, laas.Number); assert(ok2);
	eid := transmute(Entity)eid_token.int_value;
    
	_, ok0 := entity_data[eid];
	assert(!ok0, tprint("entity already exists!!!"));
    
	for r, i in entity_name {
		if r == '-' {
			name := entity_name[:i];
			// id := entity_name[i+1:];
			em_make_entity(aprint(name), eid);
			break;
		}
	}
    
	for {
		for laas.is_token(&lexer, laas.New_Line) do laas.eat(&lexer);
		component_name_ident, ok := laas.expect(&lexer, laas.Identifier);
		if !ok do break;
        
		nl, ok2 := laas.expect(&lexer, laas.New_Line);
		assert(ok2);
        
		ti := _get_component_ti_from_name(component_name_ident.value);
		comp := _em_get_component_internal(eid, ti.id);
		if comp == nil do comp = _em_add_component_internal(eid, ti.id);
        
		root: laas.Token;
		ok4 := laas.get_next_token(&lexer, &root); assert(ok4);
		wbml.parse_value(&lexer, root, comp, ti);
	}
    
	return eid;
}

_get_component_ti_from_name :: proc(name: string) -> ^rt.Type_Info {
	for tid, data in component_types {
		if tprint(data.ti) == name do return data.ti;
	}
	assert(false, tprint("Couldnt find: ", name)); // todo(josh): handle components that exist on an entity but have been deleted
	return nil;
}





serialize_entity_to_file :: proc(eid: Entity, folder_path: string) {
	sb: strings.Builder;
	defer strings.destroy_builder(&sb);
    
	sbprint(&sb, eid, "\n");
	entity_data, ok := entity_data[eid];
	assert(ok);
	for c in entity_data.components {
		comp_data, ok2 := component_types[c];
		assert(ok2);
        
		sbprint(&sb, comp_data.ti, "\n");
        
		comp := cast(^Component_Base)_em_get_component_internal(eid, c);
		assert(comp != nil);
		wbml.serialize_with_type_info("", comp, comp_data.ti, &sb, 0);
	}
    
	os.write_entire_file(tprint(folder_path, entity_data.name, "-", eid, ".e"), cast([]u8)strings.to_string(sb));
}





draw_entity_window :: proc() {
	if imgui.begin("Scene") {
		if imgui.button("Create Entity") {
			em_make_entity();
		}
        
		for eid in active_entities {
			e_data, ok := entity_data[eid];
			assert(ok);
            
			name := tprint(e_data.name," - ", eid);
			imgui.push_id(name); defer imgui.pop_id();
            
			if imgui.collapsing_header(name) {
				imgui.indent(); defer imgui.unindent();
                
				entity_name_buffer: [64]u8;
				if imgui.input_text("Name", entity_name_buffer[:], .EnterReturnsTrue) {
					// note(josh): @Leak @Alloc, we stomp on the current name and leak it but that should be fine because this is debug only!!
					e_data.name = aprint(cast(string)cast(cstring)&entity_name_buffer[0]);
					entity_data[eid] = e_data;
					entity_name_buffer = {};
				}
                
				for c in e_data.components {
					component_data, ok := component_types[c];
					assert(ok);
					defer component_types[c] = component_data;
                    
					imgui.push_id(tprint(component_data.ti)); defer imgui.pop_id();
                    
					for i in 0..<component_data.storage.len {
						ptr := cast(^Component_Base)mem.ptr_offset(cast(^u8)component_data.storage.data, i * component_data.ti.size);
						if ptr.e == eid {
							wb.imgui_struct_ti("", ptr, component_data.ti);
							break;
						}
					}
				}
                
                
                
				comp_name_buffer: [64]byte;
				just_opened := false;
				if imgui.button("+") {
					comp_name_buffer = {};
					imgui.open_popup("Add component");
					just_opened = true;
				}
                
				if imgui.begin_popup("Add component") {
					if just_opened do imgui.set_keyboard_focus_here(0);
					imgui.input_text("Component", comp_name_buffer[:]);
                    
					for tid, comp in component_types {
						name := tprint(comp.ti);
						input := cast(string)cast(cstring)&comp_name_buffer[0];
						name_lower  := string_to_lower(name);
						input_lower := string_to_lower(input);
                        
						if len(input_lower) > 0 && string_starts_with(name_lower, input_lower) {
							if imgui.button(name) {
								_em_add_component_internal(eid, tid);
								imgui.close_current_popup();
							}
						}
					}
					imgui.end_popup();
				}
			}
		}
	}
	imgui.end();
}


// Globals

component_types: map[typeid]Component_Type;
active_entities: [dynamic]int;
entity_data: map[Entity]Entity_Data;
entities_to_destroy:   [dynamic]int;



Entity :: int;

Entity_Data :: struct {
	name: string,
	components: [dynamic]typeid,
}

Component_Type :: struct {
	ti: ^rt.Type_Info,
	storage: mem.Raw_Dynamic_Array,
	reusable_indices: [dynamic]int,
    
	update_proc: proc(rawptr, f32),
	render_proc: proc(rawptr),
	init_proc: proc(rawptr),
}