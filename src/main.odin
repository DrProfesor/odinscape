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

//cube_model: ^Model_Asset;

main_collision_scene: coll.Collision_Scene;
//scene: Scene;

gameplay_camera := wb.current_camera;

main_init :: proc() {
	//
	init_key_config();
	//init_entities();
	//init_abilities();
    
	//
	//scene = scene_init("main");
    
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
        
		load_scene("resources/scenes/main");
	}
    
	//
	//add_selected_unit(player_input_manager.player_entity);
	//focus_camera_on_guy(player_input_manager.player_entity);
    
	//
	wb.register_debug_program("Odinscape Debug", debug_window_proc, nil);
	//logln(wb.shader_texture);
}

load_scene :: proc(scene_folder_path: string) {
	files := get_all_filepaths_recursively(scene_folder_path);
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

last_mouse_pos: Vec2;
main_update :: proc(dt: f32) {
    if platform.get_input_down(platform.Input.Escape) do wb.end_workspace(wb.current_workspace);
    
    //update_player_input();
    
	//update_entities();
    //update_inspector_window();
}

main_render :: proc(dt: f32) {
	//render_entities();
}

main_end :: proc() {
	//scene_end(scene);
	//shutdown_entities();
	key_config_save();
}

debug_window_proc :: proc(_: rawptr) {
	//imgui.checkbox("Debug Colliders", &debugging_colliders);
	//imgui.checkbox("Entity Handles", &debug_draw_entity_handles);
	//imgui.checkbox("Ability Editor", &ability_manager.show_ability_editor);
}



main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Workspace{"Main", main_init, main_update, main_render, main_end});
}

