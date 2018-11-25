package main

using import  "core:math"
using import  "core:fmt"
      import  "core:os"
      import  "shared:workbench/wbml"

SCENE_DIRECTORY :: "resources/scenes/";

Manifest_Entry :: struct {
	id: string,
	path: string
}

Entity_Manifest :: struct {
	entries: []Manifest_Entry
}

Scene :: struct {
	manifest: Entity_Manifest,
}

scene_init :: proc(scene_file : string) {
	scene_data, ok := os.read_entire_file(tprint(SCENE_DIRECTORY, scene_file, ".scene"));
	assert(ok, tprint("Couldn't find ", SCENE_DIRECTORY, scene_file, ".scene"));
	defer delete(scene_data);

	scene := wbml.deserialize(Scene, string(scene_data));

	logln(scene);
}

scene_update :: proc() {

}

scene_end :: proc() {

}