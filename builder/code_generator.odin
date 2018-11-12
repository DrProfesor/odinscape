package builder

import wb "shared:workbench"

when wb.DEVELOPER {

import "core:os"
using import "core:fmt"

import "shared:workbench/wbml"

generated_code: String_Buffer;
indent_level: int = 0;

run_code_generator :: proc() {
	sbprint(&generated_code,
`package main

using import "core:fmt"
      import wb "shared:workbench"

`);

	// Components
	{
		component_types_data, ok := os.read_entire_file(ODINSCAPE_DIRECTORY + "component_types.wbml");
		assert(ok, tprint("Couldn't find ", ODINSCAPE_DIRECTORY + "component_types.wbml"));
		defer delete(component_types_data);
		components := wbml.deserialize([]string, cast(string)component_types_data);

		enum_begin("Component_Type"); {
			defer enum_end();
			for component_name in components {
				enum_field(component_name);
			}
		}

		for component_name in components {
			line(tprint("all__", component_name, ": [dynamic]", component_name, ";"));
		}

		line("");

		procedure_begin("add_component", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			line("entity_data, ok := all_entities[entity]; assert(ok);");
			line("defer all_entities[entity] = entity_data;");
			line("_t: Type; _t.entity = entity;");
			for component_name in components {
				line_indent(tprint("when Type == ", component_name, " {")); {
					defer line_outdent("}");
					line(tprint("new_length := append(&all__", component_name, ", _t);"));
					line(tprint("t := &all__", component_name, "[new_length-1];"));
					line(tprint("append(&entity_data.component_types, Component_Type.", component_name, ");"));
					emit_component_proc_call(tprint("init__", component_name), component_name);
					line(tprint("return t;"));
				}
			}
			line(`panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml"));`);
			line("return nil;");
		}

		procedure_begin("get_component", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			for component_name in components {
				line_indent(tprint("when Type == ", component_name, " {")); {
					defer line_outdent("}");
					line_indent(tprint("for _, i in all__", component_name, " {")); {
						defer line_outdent("}");
						line(tprint("c := &all__", component_name, "[i];"));
						line("if c.entity == entity do return c;");
						line("return nil;");
					}
				}
			}
			line(`panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml"));`);
			line("return nil;");
		}

		procedure_begin("call_component_updates"); {
			defer procedure_end();
			for component_name in components {
				emit_component_proc_call(tprint("update__", component_name), component_name);
			}
		}

		procedure_begin("call_component_renders"); {
			defer procedure_end();
			for component_name in components {
				emit_component_proc_call(tprint("render__", component_name), component_name);
			}
		}

		procedure_begin("destroy_marked_entities"); {
			defer procedure_end();
			line_indent("for entity_id in entities_to_destroy {"); {
				defer line_outdent("}");
				line("entity, ok := all_entities[entity_id]; assert(ok);");
				line_indent("for comp_type in entity.component_types {"); {
					defer line_outdent("}");
					line("switch comp_type {"); {
						defer line("}");
						for component_name in components {
							line_indent(tprint("case Component_Type.", component_name, ":")); {
								defer line_outdent("");
								line_indent(tprint("for _, i in all__", component_name, " {")); {
									defer line_outdent("}");
									line(tprint("comp := &all__", component_name, "[i];"));
									line_indent("if comp.entity == entity_id {"); {
										defer line_outdent("}");
										emit_component_proc_call(tprint("destroy__", component_name), component_name);
										line(tprint("unordered_remove(&all__", component_name, ", i);"));
										line("break;");
									}
								}
							}
						}
					}
				}
				line("clear(&entity.component_types);");
				line("append(&available_component_lists, entity.component_types);");
				line("delete_key(&all_entities, entity_id);");
			}
			line("clear(&entities_to_destroy);");
		}
	}

	os.write_entire_file("./src/odinscape_generated_code.odin", cast([]u8)to_string(generated_code));
	delete(generated_code);
}



Component_Definition :: struct {
	type_name: string,

	init_proc: string,
	update_proc: string,
	render_proc: string,
	destroy_proc: string,
}



emit_component_proc_call :: proc(proc_name: string, comp_name: string) {
	line_indent(tprint("when #defined(", proc_name, ") {")); {
		defer line_outdent("}");
		line_indent(tprint("for _, i in all__", comp_name, " {")); {
			defer line_outdent("}");
			line(tprint("c := &all__", comp_name, "[i];"));
			line(tprint(proc_name, "(c);"));
		}
	}
}



print_indents :: proc() {
	for i in 0..indent_level-1 {
		sbprint(&generated_code, "\t");
	}
}



struct_begin :: proc(struct_name: string) {
	print_indents();
	sbprint(&generated_code, struct_name, " :: struct {\n");
	indent_level += 1;
}
struct_field :: proc(field_name: string) {
	print_indents();
	sbprint(&generated_code, field_name, ",\n");
}
struct_end :: proc() {
	indent_level -= 1;
	print_indents();
	sbprint(&generated_code, "}\n\n");
}



union_begin :: proc(struct_name: string) {
	print_indents();
	sbprint(&generated_code, struct_name, " :: union {\n");
	indent_level += 1;
}
union_field :: proc(field_name: string) {
	print_indents();
	sbprint(&generated_code, field_name, ",\n");
}
union_end :: proc() {
	indent_level -= 1;
	print_indents();
	sbprint(&generated_code, "}\n\n");
}



enum_begin :: proc(struct_name: string) {
	print_indents();
	sbprint(&generated_code, struct_name, " :: enum {\n");
	indent_level += 1;
}
enum_field :: proc(field_name: string) {
	print_indents();
	sbprint(&generated_code, field_name, ",\n");
}
enum_end :: proc() {
	indent_level -= 1;
	print_indents();
	sbprint(&generated_code, "}\n\n");
}



Parameter :: struct {
	name: string,
	type: string,
}
procedure_begin :: proc(name: string, return_type: string = nil, params: ..Parameter) {
	print_indents();
	sbprint(&generated_code, name, " :: proc(");
	comma := "";
	for param in params {
		sbprint(&generated_code, comma);
		comma = ", ";
		sbprint(&generated_code, param.name, ": ", param.type);
	}
	sbprint(&generated_code, ") ");
	if return_type != "" {
		sbprint(&generated_code, "-> ", return_type, " ");
	}
	sbprint(&generated_code, "{\n");
	indent_level += 1;
}
line :: inline proc(code: string) {
	print_indents();
	sbprint(&generated_code, code, "\n");
}
line_indent :: inline proc(code: string) {
	line(code);
	indent_level += 1;
}
line_outdent :: inline proc(code: string) {
	indent_level -= 1;
	line(code);
}
procedure_end :: proc() {
	indent_level -= 1;
	print_indents();
	sbprint(&generated_code, "}\n\n");
}

}