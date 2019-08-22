package main

using import "core:math"

import platform "shared:workbench/platform"
import wb       "shared:workbench"

editor_enabled := false;

Base_Speed :: 5;

editor_init :: proc() {
    
}

editor_update :: proc() {
    
	if (platform.get_input_down(key_config.toggle_editor)) {
		editor_enabled = !editor_enabled;
	}
    
	if !editor_enabled do return;
    
	// Editor move camera
	if platform.get_input(key_config.camera_scroll) {
        
	} 
	else if platform.get_input(key_config.camera_free_move) {
        
        move_direction := Vec3{};
        speed := Base_Speed;
        if platform.get_input(key_config.camera_speed_boost) do
            speed = speed * 2;
        
        if platform.get_input(key_config.camera_forward) {
            move_direction.z += 1;
        }
        if platform.get_input(key_config.camera_back) {
            move_direction.z -= 1;
        }
        if platform.get_input(key_config.camera_left) {
            move_direction.x -= 1;
        }
        if platform.get_input(key_config.camera_right) {
            move_direction.x += 1;
        }
        if platform.get_input(key_config.camera_up) {
            move_direction.y += 1;
        }
        if platform.get_input(key_config.camera_down) {
            move_direction.y -= 1;
        }
        
        wb.wb_camera.position += move_direction;
	}
    
	draw_entity_window();
}