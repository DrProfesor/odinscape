package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/ecs"
import wb    "shared:workbench"
import wbml  "shared:workbench/wbml"

RESOURCES := "resources/";
SCENE_DIRECTORY := "resources/scenes/";

scene_init :: proc(scene_name : string) {
    ecs.load_scene(fmt.tprint(SCENE_DIRECTORY, scene_name));
}

scene_end :: proc(scene_name : string) {
    ecs.unload_scene();
}

get_entity_path :: proc(scene_name : string) -> string {
	return fmt.tprint(SCENE_DIRECTORY, scene_name, "/entities/");
}