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
    em_load_scene(tprint(SCENE_DIRECTORY, scene_name));
}

scene_end :: proc(scene_name : string) {
    em_unload_scene();
}

get_entity_path :: proc(scene_name : string) -> string {
	return tprint(SCENE_DIRECTORY, scene_name, "/entities/");
}