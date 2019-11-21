package editor


using import "core:fmt"

using import "shared:workbench/types"
using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

using import "../configs"
using import "../physics"

import wb_plat "shared:workbench/platform"
import wb      "shared:workbench"
import "shared:workbench/external/imgui"

Base_Speed : f32 = 5;

editor_enabled := false;

init :: proc() {
    init_resources_window();
}

update :: proc(dt: f32) {
    
    if (wb_plat.get_input_down(key_config.toggle_editor)) {
        editor_enabled = !editor_enabled;
    }
    
    if !editor_enabled do return;
    
    update_resources_window(dt);
    update_player_window(dt);
    
    if imgui.begin("Scene View", nil) {
        window_size := imgui.get_window_size();
        
        imgui.image(imgui.TextureID(uintptr(wb.wb_camera.framebuffer.textures[0].gpu_id)),
                    imgui.Vec2{window_size.x - 10, window_size.y - 30},
                    imgui.Vec2{0,1},
                    imgui.Vec2{1,0});
    } imgui.end();
    
    // Editor move camera
    if wb_plat.get_input(key_config.camera_scroll) {
        
    }
    
    if wb_plat.get_input(key_config.camera_free_move) {
        wb.do_camera_movement(&wb.wb_camera, dt, Base_Speed, Base_Speed * 3, Base_Speed * 0.3);
    }
    
    if wb_plat.get_input_down(key_config.editor_select) {
        mouse_world := wb.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
        
        hits := make([dynamic]RaycastHit, 0, 10);
        hit := raycast(wb.wb_camera.position, mouse_direction * 100, &hits);
        
        if hit > 0 {
            first_hit := hits[0];
            selected_entity= first_hit.e;
        }
    }
    
    if selected_entity != 0 {
        transform, ok := get_component(selected_entity, Transform);
        wb.gizmo_manipulate(&transform.position, &transform.scale, &transform.rotation);
    }
    
    draw_scene_window();
}

render :: proc() {
    transform, ok := get_component(selected_entity, Transform);
    if ok {
        wb.gizmo_render(transform.position, transform.scale, transform.rotation);
    }
}