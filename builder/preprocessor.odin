package builder

import wb "shared:workbench"
import    "core:os"

using import "core:fmt"
using import "shared:workbench/laas"

import "shared:workbench/wbml"

// (jake): This function will run through the entire code base.
// If you ever need to do something like that probably do it here
// Current tasks:
//   - handling tags in the codebase
run_preprocessor :: proc() {
	all_source_files := wb.get_all_entries_strings_in_directory(ODINSCAPE_DIRECTORY, true);
	for source_file in all_source_files {
		{
			//
			if wb.is_directory(source_file) do continue;

			//
			ext, ok := wb.get_file_extension(source_file);
			if !ok do continue;
			if ext != ".odin" do continue;
		}

		source_code, ok := os.read_entire_file(source_file);
		assert(ok);

		lexer := Lexer{string(source_code), 0, 0, 0, nil};
		token: Token;

		is_comment := 0;
		is_tag := false;
		current_line := 0;
		current_tags : [dynamic]string = {};

		// (jake): Look for tags that are in comments
		// once found we will collect some data and then process the tagee
		for get_next_token(&lexer, &token) {

			switch value_kind in token.kind {
				case Symbol: {

					switch value_kind.value {
						case '/': {
							is_comment += 1;
						}

						case '@': {
							if is_comment >= 2 {
								is_tag = true;
							}
						}
					}

				}
				case Identifier: {
					if is_tag {
						append(&current_tags, token.slice_of_text);
						is_tag = false;
					}
				}
				case New_Line: {

					if len(current_tags) > 0 {

						entity_type: string;
						entity: string;

						// (jake): we need to build up some data about what we are tagging
						// just keep using the lexer to get the name and type of
						// thing we are tagging
						loop: for get_next_token(&lexer, &token) {
							switch token_kind in token.kind {
								case Identifier: {
									if entity == "" do
										entity = token.slice_of_text;
									else {
										entity_type = token.slice_of_text;
										break loop;
									}
								}
							}
						}

						for tag in current_tags do
							process_entity_tag(tag, entity, entity_type);
					}

					clear(&current_tags);
					is_tag = false;
					is_comment = 0;
				}
			}

 		}
	}
}

process_entity_tag :: proc(tag : string, entity : string, entity_type : string) {
	switch tag {
		case "Component": {
			append(&components, entity);
		}
	}
}