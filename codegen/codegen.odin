package codegen

import "core:fmt"
import "core:strings"
import "core:os"
import "core:odin/ast"
import "core:odin/parser"

import "shared:wb/logging"
import "shared:wb/laas"
import "shared:wb/basic"

SRC :: "./src";

main :: proc() {
	entity_types: [dynamic]string;
    entity_inits: map[string]string;

	for fp in basic.get_all_filepaths_recursively(SRC) {
		if !basic.string_ends_with(fp, ".odin") do continue;

		src, ok := os.read_entire_file(fp);
        assert(ok, fp);

        file: ast.File;
        file.src = src;
        file.fullpath = fp;
        pp: parser.Parser;
        parseok := parser.parse_file(&pp, &file);
        assert(parseok);

        for decl in file.decls {
            switch decl_kind in decl.derived {
                case ast.Value_Decl: {
                    for attribute in decl_kind.attributes {
                        for elem in attribute.elems {
                            switch elem_kind in elem.derived {
                                case ast.Ident: {
                            		if elem_kind.name == "entity" {
                            			append(&entity_types, decl_kind.names[0].derived.(ast.Ident).name);	
                            		}

                                    if elem_kind.name == "entity_init" {
                                        // What a hack
                                        entity_inits[entity_types[len(entity_types)-1]] = decl_kind.names[0].derived.(ast.Ident).name;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
	}

	storage_builder: strings.Builder;
    add_switch_builder: strings.Builder;
    destroy_switch_builder: strings.Builder;
    type_builder: strings.Builder;
    create_switch: strings.Builder;
    union_builder: strings.Builder;
    init_builder: strings.Builder;

    sbprint :: proc(builder: ^strings.Builder, args: ..any) {
        fmt.sbprint(buf=builder, args=args, sep="");
    }

    for t in entity_types {
    	sbprint(&storage_builder, "\nall_",t,": [dynamic]^",t,";");
    	sbprint(&add_switch_builder, "\n\t\tcase ",t,": { \n\t\t\tappend(&all_",t,", cast(^",t,") e); \n\t\t\t(cast(^",t,") e).base = e;\n\t\t}");
    	sbprint(&destroy_switch_builder, "\n\t\tcase ",t,": for ep, i in all_",t," do if cast(^Entity) ep == e { unordered_remove(&all_",t,", i); break; }");
        sbprint(&type_builder, "\n\ttypeid_of(",t,"),");
        sbprint(&create_switch, "\n\t\tcase ",t,": e.kind = ",t,"{};");
        sbprint(&union_builder, "\n\t",t,",");
    }

    for t, init_proc in entity_inits {
        sbprint(&init_builder, "\n\t\tcase ", t, ": ", init_proc, "(cast(^",t,") e, is_creation);");
    }

    generated_code, _ := strings.replace(GENERATED_CODE_FORMAT, "{storage}", strings.to_string(storage_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{add_switch}", strings.to_string(add_switch_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{destroy_switch}", strings.to_string(destroy_switch_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{types}", strings.to_string(type_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{create_switch}", strings.to_string(create_switch), 1);
    generated_code, _ = strings.replace(generated_code, "{union}", strings.to_string(union_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{init_switch}", strings.to_string(init_builder), 1);

    generated_code, _ = strings.replace_all(generated_code, "{type_count}", fmt.tprint(len(entity_types)));

    os.write_entire_file("./src/entity/entity_generated.odin", transmute([]byte)generated_code);
}

GENERATED_CODE_FORMAT :: 
`package entity

import "shared:wb"
{storage}

Entity_Union :: union {{union}
}

entity_typeids := [{type_count}]typeid{{types}
};

_add_entity :: proc(e: ^Entity) {
	switch kind in e.kind {{add_switch}
	}
}

_destroy_entity :: proc(e: ^Entity) {
	switch kind in e.kind {{destroy_switch}
	}
}

create_entity_by_type :: proc(t: typeid) -> Entity {
    e := _create_entity();

    switch t {{create_switch}
    }

    return e;
}

init_entity :: proc(e: ^Entity, is_creation := false) {
    #partial switch kind in e.kind {{init_switch}
        case: break;
    }
}

`;