package prebuild

import wb "shared:workbench"
logln :: wb.logln;

when wb.DEVELOPER {

import "core:os"
using import "core:fmt"

import    "shared:workbench/wbml"

ODINSCAPE_DIRECTORY :: "../src/";

generated_code: String_Buffer;
indent_level: int = 0;

main :: proc() {
	sbprint(&generated_code,
`package main

using import "core:fmt"

`);

	// Components
	{
		Component_Definition :: struct {
			type_name: string,
			storage_variable: string,

			init_proc: string,
			update_proc: string,
			render_proc: string,
			destroy_proc: string,
		}

		component_types_data, ok := os.read_entire_file(ODINSCAPE_DIRECTORY + "component_types.wbml");
		assert(ok, tprint("Couldn't find ", ODINSCAPE_DIRECTORY + "component_types.wbml"));
		defer delete(component_types_data);
		components := wbml.deserialize([]Component_Definition, cast(string)component_types_data);

		union_begin("Component_Type"); {
			defer union_end();
			for c in components {
				union_field(c.type_name);
			}
		}

		procedure_begin("add_component", "^Type", Parameter{"entity", "Entity"}, Parameter{"$Type", "typeid"}); {
			defer procedure_end();
			for c in components {
				procedure_line(tprint("when Type == ", c.type_name, " {")); {
					defer procedure_line("}");
					indent_level += 1;
					defer indent_level -= 1;
					procedure_line("_t: Type; _t.entity = entity;");
					procedure_line(tprint("append(&", c.storage_variable, ", _t);"));
					procedure_line(tprint("t := &", c.storage_variable, "[len(", c.storage_variable, ")-1];"));
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
				procedure_line(tprint("when Type == ", c.type_name, " {")); {
					defer procedure_line("}");
					// TODO return not found instead of defaulting to panic
					indent_level += 1;
					defer indent_level -= 1;
					procedure_line(tprint("for _, i in ", c.storage_variable, " {")); {
						defer procedure_line("}");
						indent_level += 1;
						defer indent_level -= 1;
						procedure_line(tprint("c := &", c.storage_variable, "[i]; if c.entity == entity do return c;"));
					}
				}
			}
			procedure_line(`panic(tprint("No generated code for type ", type_info_of(Type), " in get_component(). Make sure you add your new component types to component_types.wbml")); return nil;`);
		}

		procedure_begin("destroy_component", "", Parameter{"component", "$Type"}); {
			defer procedure_end();
			for c in components {
				if c.destroy_proc == "" do continue;
				procedure_line(tprint("when Type == ", c.type_name, " {")); {
					defer procedure_line("}");
					indent_level += 1;
					defer indent_level -= 1;
					procedure_line(tprint("for _, i in ", c.storage_variable, " {")); {
						defer procedure_line("}");
						indent_level += 1;
						defer indent_level -= 1;
						procedure_line(tprint("c := &", c.storage_variable, "[i]; if c.entity == entity do return c;"));
					}
				}
			}
		}

		procedure_begin("call_component_updates"); {
			defer procedure_end();
			for c in components {
				if c.update_proc == "" do continue;
				procedure_line(tprint("for _, i in ", c.storage_variable, " {")); {
					defer procedure_line("}");
					indent_level += 1;
					defer indent_level -= 1;
					procedure_line(tprint("c := &", c.storage_variable, "[i]; ", c.update_proc, "(c);"));
				}
			}
		}

		// copy paste from above call_component_updates
		procedure_begin("call_component_renders"); {
			defer procedure_end();
			for c in components {
				if c.render_proc == "" do continue;
				procedure_line(tprint("for _, i in ", c.storage_variable, " {")); {
					defer procedure_line("}");
					indent_level += 1;
					defer indent_level -= 1;
					procedure_line(tprint("c := &", c.storage_variable, "[i]; ", c.render_proc, "(c);"));
				}
			}
		}

		// copy paste from above call_component_updates
		procedure_begin("call_component_destroys"); {
			defer procedure_end();
			for c in components {
				if c.destroy_proc == "" do continue;
				procedure_line(tprint("for _, i in ", c.storage_variable, " {")); {
					defer procedure_line("}");
					indent_level += 1;
					defer indent_level -= 1;
					procedure_line(tprint("c := &", c.storage_variable, "[i]; ", c.destroy_proc, "(c);"));
				}
			}
		}
	}

	os.write_entire_file("../src/odinscape_generated_code.odin", cast([]u8)to_string(generated_code));
	delete(generated_code);
}



indent :: proc() {
	for i in 0..indent_level-1 {
		sbprint(&generated_code, "\t");
	}
}



struct_begin :: proc(struct_name: string) {
	indent();
	sbprint(&generated_code, struct_name, " :: struct {\n");
	indent_level += 1;
}
struct_field :: proc(field_name: string) {
	indent();
	sbprint(&generated_code, field_name, ",\n");
}
struct_end :: proc() {
	indent_level -= 1;
	indent();
	sbprint(&generated_code, "}\n\n");
}



union_begin :: proc(struct_name: string) {
	indent();
	sbprint(&generated_code, struct_name, " :: union {\n");
	indent_level += 1;
}
union_field :: proc(field_name: string) {
	indent();
	sbprint(&generated_code, field_name, ",\n");
}
union_end :: proc() {
	indent_level -= 1;
	indent();
	sbprint(&generated_code, "}\n\n");
}



Parameter :: struct {
	name: string,
	type: string,
}
procedure_begin :: proc(name: string, return_type: string = nil, params: ..Parameter) {
	indent();
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
procedure_line :: proc(line: string) {
	indent();
	sbprint(&generated_code, line, "\n");
}
procedure_end :: proc() {
	indent_level -= 1;
	indent();
	sbprint(&generated_code, "}\n\n");
}

}
