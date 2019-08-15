package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"
import wb        "shared:workbench"
import platform  "shared:workbench/platform"
import coll      "shared:workbench/collision"
import wbmath    "shared:workbench/math"
import ai        "shared:workbench/external/assimp"
import imgui     "shared:workbench/external/imgui"

DEVELOPER :: true;

main_collision_scene: coll.Collision_Scene;
gameplay_camera := wb.current_camera;

game_init :: proc() {
	// camera
	{
		wb.current_camera.is_perspective = true;
		wb.current_camera.size = 70;
		wb.current_camera.position = Vec3{};
		wb.current_camera.rotation = Quat{};
	}
    
    // entities
	{
		em_add_component_type(Transform, nil, nil);
        
		scene_init("main");
	}
    
	//
	//add_selected_unit(player_input_manager.player_entity);
	//focus_camera_on_guy(player_input_manager.player_entity);
    
	//
	wb.register_debug_program("Odinscape Debug", debug_window_proc, nil);
}

game_update :: proc() {

}

game_end :: proc() {
	scene_end("main");
}