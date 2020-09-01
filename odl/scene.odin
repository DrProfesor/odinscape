package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/ecs"
import wb    "shared:wb"
import wbml  "shared:wb/wbml"

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