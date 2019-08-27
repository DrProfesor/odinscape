package main

using import "core:math"
using import "core:fmt"

using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"

import wb_plat "shared:workbench/platform"
import wb_gpu  "shared:workbench/gpu"
import wb_math  "shared:workbench/math"
import wb      "shared:workbench"
import         "shared:workbench/external/imgui"

editor_enabled := false;

Base_Speed := Vec3{1,1,1};

editor_init :: proc() {
    
}

editor_update :: proc(dt: f32) {
    
	if (wb_plat.get_input_down(key_config.toggle_editor)) {
		editor_enabled = !editor_enabled;
	}
    
	if !editor_enabled do return;
    
    if imgui.begin("Scene View", nil) {
	    window_size := imgui.get_window_size();
        
		imgui.image(rawptr(uintptr(wb.wb_camera.framebuffer.texture)),
                    imgui.Vec2{window_size.x - 10, window_size.y - 30},
                    imgui.Vec2{0,1},
                    imgui.Vec2{1,0});
	} imgui.end();
    
	// Editor move camera
	if wb_plat.get_input(key_config.camera_scroll) {
        
	}
    
	if wb_plat.get_input(key_config.camera_free_move) {
        
        speed := Base_Speed;
        if wb_plat.get_input(key_config.camera_speed_boost) do
            speed = speed * Vec3{2,2,2};
        
        speed = speed * Vec3{dt, dt, dt};
        
        if wb_plat.get_input(key_config.camera_forward) {
            wb.wb_camera.position += wb_gpu.camera_forward(&wb.wb_camera) * speed;
        }
        if wb_plat.get_input(key_config.camera_back) {
            wb.wb_camera.position += wb_gpu.camera_back(&wb.wb_camera) * speed;
        }
        if wb_plat.get_input(key_config.camera_left) {
            wb.wb_camera.position += wb_gpu.camera_left(&wb.wb_camera) * speed;
        }
        if wb_plat.get_input(key_config.camera_right) {
            wb.wb_camera.position += wb_gpu.camera_right(&wb.wb_camera) * speed;
        }
        if wb_plat.get_input(key_config.camera_up) {
            wb.wb_camera.position += wb_gpu.camera_up(&wb.wb_camera) * speed;
        }
        if wb_plat.get_input(key_config.camera_down) {
            wb.wb_camera.position += wb_gpu.camera_down(&wb.wb_camera) * speed;
        }
        
        mouse_delta := wb_plat.mouse_screen_position_delta;
        qx := axis_angle(Vec3{0,1,0}, -mouse_delta.x * dt);
        qy := axis_angle(wb_gpu.camera_right(&wb.wb_camera), mouse_delta.y * dt);
        wb.wb_camera.rotation = mul(mul(qy, qx), wb.wb_camera.rotation);
	}
    
    //if wb_plat.get_input_down(key_config.editor_select) 
    {
        mouse_world := wb_gpu.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb_gpu.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
        
        wb.draw_debug_line(mouse_world, mouse_world + mouse_direction * 10, COLOR_GREEN);
        
        hits := make([dynamic]RaycastHit, 0, 10);
        hit := raycast(mouse_world, mouse_direction * 100, &hits);
        
        logln(mouse_world, "  ", mouse_direction, "  ", hit);
    }
    
    draw_entity_window();
}