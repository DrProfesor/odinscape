package builder

import wb "shared:workbench"

when wb.DEVELOPER {

import "core:os"
using import "core:fmt"

import    "shared:workbench/wbml"

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
		Component_Definition :: struct {
			type_name: string,

			init_proc: string,
			update_proc: string,
			render_proc: string,
			destroy_proc: string,
		}

		component_types_data, ok := os.read_entire_file(ODINSCAPE_DIRECTORY + "component_types.wbml");
		assert(ok, tprint("Couldn't find ", ODINSCAPE_DIRECTORY + "component_types.wbml"));
		defer delete(component_types_data);
		components := wbml.deserialize([]Component_Definition, cast(string)component_types_data);

		enum_begin("Component_Type"); {
			defer enum_end();
			for c in components {
				enum_field(c.type_name);
			}
		}

		for c in components {
			procedure_line(tprint("all_", c.type_name, ": [dynamic]", c.type_name, ";"));
		}

		procedure_line("");

		procedure_begin("add_component", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			procedure_line("entity_data, ok := all_entities[entity]; assert(ok);");
			procedure_line("defer all_entities[entity] = entity_data;");
			procedure_line("_t: Type; _t.entity = entity;");
			for c in components {
				procedure_line_indent(tprint("when Type == ", c.type_name, " {")); {
					defer procedure_line_outdent("}");
					procedure_line(tprint("append(&all_", c.type_name, ", _t);"));
					procedure_line(tprint("t := &all_", c.type_name, "[len(all_", c.type_name, ")-1];"));
					procedure_line(tprint("append(&entity_data.component_types, Component_Type.", c.type_name, ");"));
					if c.init_proc != "" {
						procedure_line(tprint(c.init_proc, "(t);"));
					}
					procedure_line(tprint("return t;"));
				}
			}
			procedure_line(`panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml")); return nil;`);
		}

		procedure_begin("get_component", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			for c in components {
				procedure_line_indent(tprint("when Type == ", c.type_name, " {")); {
					defer procedure_line_outdent("}");
					// TODO return not found instead of defaulting to panic
					procedure_line_indent(tprint("for _, i in all_", c.type_name, " {")); {
						defer procedure_line_outdent("}");
						procedure_line(tprint("c := &all_", c.type_name, "[i]; if c.entity == entity do return c;"));
					}
				}
			}
			procedure_line(`panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml")); return nil;`);
		}

		procedure_begin("call_component_updates"); {
			defer procedure_end();
			for c in components {
				if c.update_proc == "" do continue;
				procedure_line_indent(tprint("for _, i in all_", c.type_name, " {")); {
					defer procedure_line_outdent("}");
					procedure_line(tprint("c := &all_", c.type_name, "[i]; ", c.update_proc, "(c);"));
				}
			}
		}

		// copy paste from above call_component_updates
		procedure_begin("call_component_renders"); {
			defer procedure_end();
			for c in components {
				if c.render_proc == "" do continue;
				procedure_line_indent(tprint("for _, i in all_", c.type_name, " {")); {
					defer procedure_line_outdent("}");
					procedure_line(tprint("c := &all_", c.type_name, "[i]; ", c.render_proc, "(c);"));
				}
			}
		}

		procedure_begin("destroy_marked_entities"); {
			defer procedure_end();
			procedure_line_indent("for entity_id in entities_to_destroy {"); {
				defer procedure_line_outdent("}");
				procedure_line("entity, ok := all_entities[entity_id]; assert(ok);");
				procedure_line_indent("for comp_type in entity.component_types {"); {
					defer procedure_line_outdent("}");
					procedure_line("switch comp_type {"); {
						defer procedure_line("}");
						for c in components {
							procedure_line_indent(tprint("case Component_Type.", c.type_name, ":")); {
								defer procedure_line_outdent("");
								procedure_line_indent(tprint("for _, i in all_", c.type_name, " {")); {
									defer procedure_line_outdent("}");
									procedure_line(tprint("comp := &all_", c.type_name, "[i];"));
									procedure_line_indent("if comp.entity == entity_id {"); {
										defer procedure_line_outdent("}");
										if c.destroy_proc != "" {
											procedure_line(tprint(c.destroy_proc, "(comp);"));
										}
										procedure_line(tprint("unordered_remove(&all_", c.type_name, ", i);"));
										procedure_line("break;");
									}
								}
							}
						}
					}
				}
				procedure_line("clear(&entity.component_types);");
				procedure_line("append(&available_component_lists, entity.component_types);");
				procedure_line("delete_key(&all_entities, entity_id);");
			}
			procedure_line("clear(&entities_to_destroy);");
		}

		// procedure_begin("destroy_component", "", Parameter{"component", "$Type"}); {
		// 	defer procedure_end();
		// 	for c in components {
		// 		if c.destroy_proc == "" do continue;
		// 		procedure_line_indent(tprint("when Type == ", c.type_name, " {")); {
		// 			defer procedure_line_outdent("}");
		// 			procedure_line_indent(tprint("for _, i in all_", c.type_name, " {")); {
		// 				defer procedure_line_outdent("}");
		// 				procedure_line(tprint("c := &all_", c.type_name, "[i]; if c.entity == entity do return c;"));
		// 			}
		// 		}
		// 	}
		// }

		// copy paste from above call_component_updates
		// procedure_begin("call_component_destroys"); {
		// 	defer procedure_end();
		// 	for c in components {
		// 		if c.destroy_proc == "" do continue;
		// 		procedure_line_indent(tprint("for _, i in all_", c.type_name, " {")); {
		// 			defer procedure_line_outdent("}");
		// 			procedure_line(tprint("c := &all_", c.type_name, "[i]; ", c.destroy_proc, "(c);"));
		// 		}
		// 	}
		// }
	}

	os.write_entire_file("./src/odinscape_generated_code.odin", cast([]u8)to_string(generated_code));
	delete(generated_code);
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
procedure_line :: inline proc(line: string) {
	print_indents();
	sbprint(&generated_code, line, "\n");
}
procedure_line_indent :: inline proc(line: string) {
	procedure_line(line);
	indent_level += 1;
}
procedure_line_outdent :: inline proc(line: string) {
	indent_level -= 1;
	procedure_line(line);
}
procedure_end :: proc() {
	indent_level -= 1;
	print_indents();
	sbprint(&generated_code, "}\n\n");
}

}