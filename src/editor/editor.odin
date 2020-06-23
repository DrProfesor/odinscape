package editor


import "core:fmt"

import "shared:wb/types"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/ecs"
import "shared:wb/math"

import "../configs"
import "../physics"

import wb_plat "shared:wb/platform"
import wb      "shared:wb"
import "shared:wb/external/imgui"

Base_Speed : f32 = 5;

init :: proc() {
    init_resources_window();

    wb.register_debug_program("Resources", update_resources_window, nil);
    wb.register_debug_program("Scene", ecs.draw_scene_window, nil);
    wb.register_debug_program("Config", configs.draw_config_window, nil);
}

enabled_last_frame := false;
gizmo_state := wb.Gizmo_State{};

update :: proc(dt: f32) {
    if !wb.debug_window_open {
        enabled_last_frame = false;
        return;
    }

    if !enabled_last_frame {
        // set the camera back to the editor position
        // setting to play position will be handled by the camera controller
        wb.main_camera.position = configs.editor_config.camera_position;
        wb.main_camera.rotation = configs.editor_config.camera_rotation;
    }

    if wb_plat.get_input(configs.key_config.camera_free_move) {
        wb.do_camera_movement(wb.main_camera, dt, Base_Speed, Base_Speed * 3, Base_Speed * 0.3);

        configs.editor_config.camera_position = wb.main_camera.position;
        configs.editor_config.camera_rotation = wb.main_camera.rotation;
    }

    /*if wb_plat.get_input_down(configs.key_config.editor_select) {
        mouse_world := wb.get_mouse_world_position(wb.main_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb.get_mouse_direction_from_camera(wb.main_camera, wb_plat.mouse_unit_position);

        hits := make([dynamic]RaycastHit, 0, 10);
        hit := raycast(wb.main_camera.position, mouse_direction * 100, &hits);

        if hit > 0 {
            first_hit := hits[0];
            selected_entity= first_hit.e;
        }
    }*/

    if ecs.selected_entity != 0 {
        transform, ok := ecs.get_component(ecs.selected_entity, ecs.Transform);
        wb.gizmo_manipulate(&transform.position, &transform.scale, &transform.rotation, &gizmo_state);
    }

    enabled_last_frame = true;
}

render :: proc() {
    if !wb.debug_window_open do return;

    transform, ok := ecs.get_component(ecs.selected_entity, ecs.Transform);
    if ok {
        wb.gizmo_render();
    }
}