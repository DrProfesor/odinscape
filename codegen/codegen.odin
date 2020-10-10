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
                                	switch elem_kind.name {
                                		case "entity": {
                                			append(&entity_types, decl_kind.names[0].derived.(ast.Ident).name);	
                                		}
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

    for t in entity_types {
    	fmt.sbprint(buf=&storage_builder, args={"\nall_",t,": [dynamic]^",t,";"}, sep="");
    	fmt.sbprint(buf=&add_switch_builder, args={"\n\t\tcase ",t,": append(&all_",t,", cast(^",t,") e);"}, sep="");
    	fmt.sbprint(buf=&destroy_switch_builder, args={"\n\t\tcase ",t,": for ep, i in all_",t," do if cast(^Entity) ep == e { unordered_remove(&all_",t,", i); break; }"}, sep="");
        fmt.sbprint(buf=&type_builder, args={"\n\ttypeid_of(",t,"),"}, sep="");
    }

    generated_code, _ := strings.replace(GENERATED_CODE_FORMAT, "{storage}", strings.to_string(storage_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{add_switch}", strings.to_string(add_switch_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{destroy_switch}", strings.to_string(destroy_switch_builder), 1);
    generated_code, _ = strings.replace(generated_code, "{types}", strings.to_string(type_builder), 1);

    generated_code, _ = strings.replace_all(generated_code, "{type_count}", fmt.tprint(len(entity_types)));

    os.write_entire_file("./src/entity/entity_generated.odin", transmute([]byte)generated_code);
}

GENERATED_CODE_FORMAT :: 
`package entity
{storage}

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

`;