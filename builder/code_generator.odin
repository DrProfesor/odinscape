package builder

import wb "shared:workbench"

when wb.DEVELOPER {

import "core:os"
using import "core:fmt"
using import "core:strings"

import "shared:workbench/wbml"

generated_code: Builder;
indent_level: int = 0;

run_code_generator :: proc() {
	sbprint(&generated_code,
`package main

using import "core:fmt"
using import "core:strings"
using import "shared:workbench/pool"
      import wb "shared:workbench"
      import imgui "shared:workbench/external/imgui"
      import "shared:workbench/wbml"

`);

	// Components
	{
		enum_begin("Component_Type"); {
			defer enum_end();
			for component_name in components {
				enum_field(component_name);
			}
		}

		for component_name in components {
			line("all__", component_name, ": Pool(", component_name, ", 64);");
		}

		line("\nadd_component :: proc{add_component_type, add_component_value};\n");

		procedure_begin("add_component_type", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			line("entity_data, ok := all_entities[entity]; assert(ok);");
			line("defer all_entities[entity] = entity_data;");
			for component_name in components {
				line_indent("when Type == ", component_name, " {"); {
					defer line_outdent("}");
					line("t := pool_get(&all__", component_name, ");");
					line("t.entity = entity;");
					line("append(&entity_data.component_types, Component_Type.", component_name, ");");
					init_proc_name := tprint("init__", component_name);
					line_indent("when #defined(", init_proc_name, ") {"); {
						defer line_outdent("}");
						line(init_proc_name, "(t);");
					}
					line("return t;");
				}
			}
			line(`panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml"));`);
			line("return nil;");
		}

		procedure_begin("add_component_value", "^Type", Parameter{"entity", "Entity"}, Parameter{"component", "$Type"}); {
			defer procedure_end();
			line("entity_data, ok := all_entities[entity]; assert(ok);");
			line("defer all_entities[entity] = entity_data;");
			line("component.entity = entity;");
			for component_name in components {
				line_indent("when Type == ", component_name, " {"); {
					defer line_outdent("}");
					line("t := pool_get(&all__", component_name, ");");
					line("t^ = component;");
					line("append(&entity_data.component_types, Component_Type.", component_name, ");");
					init_proc_name := tprint("init__", component_name);
					line_indent("when #defined(", init_proc_name, ") {"); {
						defer line_outdent("}");
						line(init_proc_name, "(t);");
					}
					line("return t;");
				}
			}
			line(`panic(tprint("No generated code for type ", type_info_of(Type), " in add_component(). Make sure you add your new component types to component_types.wbml"));`);
			line("return nil;");
		}

		procedure_begin("get_component", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			for component_name in components {
				line_indent("when Type == ", component_name, " {"); {
					defer line_outdent("}");
					pool_foreach("c", component_name); {
						defer end_pool_foreach();
						line("if c.entity == entity do return c;");
					}

					line("return nil;");
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

		procedure_begin("serialize_entity_components", "string", Parameter{"entity", "Entity"}); {
			defer procedure_end();

			line("serialized : Builder;");
			line("sbprint(&serialized, tprint(\"\\\"\", all_entities[entity].name, \"\\\"\", \"\\n\"));");

			for component_name in components {
				line(component_name, "_comp := get_component(entity, ",component_name, ");");
				line_indent("if ", component_name,"_comp != nil {"); {
					defer line_outdent("}");
					line("s := wbml.serialize(",component_name, "_comp);");
					line("sbprint(&serialized, \"",component_name, `\n`,"\");");
					line("sbprint(&serialized, s);");
				}
			}

			line("return to_string(serialized);");
		}

		procedure_begin("init_entity", "bool", Parameter{"entity", "Entity"}); {
			defer procedure_end();

			for component_name in components {
				line_indent("when #defined(init__", component_name, ") {"); {
					defer line_outdent("}");
					line(component_name, "_comp := get_component(entity, ",component_name, ");");
					line_indent("if ", component_name,"_comp != nil {"); {
						defer line_outdent("}");
						line("init__",component_name, "(",  component_name,"_comp);");
					}
				}
			}
			line("return true;");
		}

		procedure_begin("deserialize_entity_comnponents", "Entity", 
			Parameter{"entity_id", "int"}, 
			Parameter{"serialized_entity", "[dynamic]string"}, 
			Parameter{"component_types", "[dynamic]string"},
			Parameter{"entity_name", "string"}); 
		{
			defer procedure_end();

			line("entity := new_entity_dangerous(entity_id, entity_name);");

			line_indent("for component_data, i in serialized_entity {");{
				defer line_outdent("}");
				line("component_type := component_types[i];");
				line_indent("switch component_type {"); {
					defer line_outdent("}");
					for component_name in components {
						line_indent("case \"", component_name, "\": {"); {
							defer line_outdent("}");
							line("component := wbml.deserialize(", component_name, ", component_data);");
							line("add_component(entity, component);");
						}
					}
				}
			}
			line("return entity;");
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
							line_indent("case Component_Type.", component_name, ": {"); {
								defer line_outdent("}");
								line("pool_loop__", component_name, ":");
								pool_foreach("comp", component_name); {
									defer end_pool_foreach();
									line_indent("if comp.entity == entity_id {"); {
										defer line_outdent("}");
										line_indent("when #defined(destroy__", component_name, ") {"); {
											defer line_outdent("}");
											line("destroy__", component_name, "(comp);");
										}
										line("pool_return(&all__", component_name, ", comp);");
										line("break pool_loop__", component_name, ";");
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

		procedure_begin("update_inspector_window"); {
			defer procedure_end();

			line_indent("if imgui.begin(\"Scene\") {"); {
				defer line_outdent("}");

				line_indent("for entity, entity_data in all_entities {"); {
					defer line_outdent("}");

					line_indent("if imgui.collapsing_header(tprint((entity_data.name == \"\" ? \"<no_name>\" : entity_data.name), \" #\", entity)) {"); {
						defer line_outdent("}");
						line_indent("for comp_type in entity_data.component_types {"); {
							defer line_outdent("}");

							line_indent("imgui.indent();");
							defer line("imgui.unindent();");

							line("switch comp_type {"); {
								defer line_outdent("}");
								for component_name in components {
									line_indent("case Component_Type.", component_name, ": {"); {
										defer line_outdent("}");

										line("pool_loop__", component_name, ":");
										pool_foreach("comp", component_name); {
											defer end_pool_foreach();
											line_indent("if comp.entity == entity {"); {
												defer line_outdent("}");
												line("wb.imgui_struct(comp, tprint(\"", component_name, "\"));");
												line("break pool_loop__", component_name, ";");
											}
										}

										line("break;");
									}
								}
							}
						}
					}
				}
			}
			line("imgui.end();");
		}

	}

	os.write_entire_file("./src/_odinscape_generated_code.odin", cast([]u8)to_string(generated_code));
	//delete(generated_code);
}



Component_Definition :: struct {
	type_name: string,

	init_proc: string,
	update_proc: string,
	render_proc: string,
	destroy_proc: string,
}



emit_component_proc_call :: proc(proc_name: string, comp_name: string) {
	line_indent("when #defined(", proc_name, ") {"); {
		defer line_outdent("}");
		pool_foreach("c", comp_name); {
			defer end_pool_foreach();
			line(proc_name, "(c);");
		}
	}
}



print_indents :: proc() {
	for i in 0..indent_level-1 {
		sbprint(&generated_code, "\t");
	}
}



pool_foreach :: proc(ident: string, component: string) {
	line_indent("for _, batch_idx in &all__", component, ".batches {");
	line("batch := &all__", component, ".batches[batch_idx];");
	line_indent("for _, idx in batch.list do if batch.empties[idx] {");
	line(ident, " := &batch.list[idx];");
}
end_pool_foreach :: proc() {
	line_outdent("}");
	line_outdent("}");
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
procedure_begin :: proc(name: string, return_type: string = "", params: ..Parameter) {
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
line :: inline proc(args: ..any) {
	print_indents();
	for arg in args {
		sbprint(&generated_code, arg);
	}
	sbprint(&generated_code, "\n");
}
line_indent :: inline proc(args: ..any) {
	print_indents();
	for arg in args {
		sbprint(&generated_code, arg);
	}
	sbprint(&generated_code, "\n");
	indent_level += 1;
}
line_outdent :: inline proc(args: ..any) {
	indent_level -= 1;
	print_indents();
	for arg in args {
		sbprint(&generated_code, arg);
	}
	sbprint(&generated_code, "\n");
}
procedure_end :: proc() {
	indent_level -= 1;
	print_indents();
	sbprint(&generated_code, "}\n\n");
}

}