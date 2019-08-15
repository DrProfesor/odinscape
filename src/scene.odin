package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
import wb    "shared:workbench"
import wbml  "shared:workbench/wbml"

RESOURCES := "resources/";
SCENE_DIRECTORY := "resources/scenes/";

scene_init :: proc(scene_name : string) {
	files := get_all_filepaths_recursively(get_entity_path(scene_name));
	defer {
		for file in files {
			delete(file);
		}
		delete(files);
	}
    
	for file in files {
		if string_ends_in(file, ".e") {
			data, ok := os.read_entire_file(file);
			assert(ok);
			defer delete(data);
			filename, ok2 := get_file_name(file);
			assert(ok2);
			load_entity_from_wbml(filename, cast(string)data);
		}
	}
}

scene_end :: proc(scene_name : string) {
	for eid in active_entities {
		serialize_entity_to_file(eid, get_entity_path(scene_name));
	}
}

get_entity_path :: proc(scene_name : string) -> string {
	return tprint(SCENE_DIRECTORY, scene_name, "/entities/");
}