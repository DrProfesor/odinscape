package editor


import "core:fmt"

import "shared:workbench/types"
import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/ecs"
import "shared:workbench/math"

import "../configs"
import "../physics"

import wb_plat "shared:workbench/platform"
import wb      "shared:workbench"
import "shared:workbench/external/imgui"

Base_Speed : f32 = 5;

init :: proc() {
    init_resources_window();

    wb.register_debug_program("Resources", update_resources_window, nil);
    wb.register_debug_program("Player", update_player_window, nil);
    wb.register_debug_program("Scene", ecs.draw_scene_window, nil);
}

update :: proc(dt: f32) {

    if (wb_plat.get_input_down(configs.key_config.toggle_editor)) {
        configs.editor_config.enabled = !configs.editor_config.enabled;

        // set the camera back to the editor position
        // setting to play position will be handled by the camera controller
        if configs.editor_config.enabled {
            wb.wb_camera.position = configs.editor_config.camera_position;
            wb.wb_camera.rotation = configs.editor_config.camera_rotation;
        }
    }

    if !configs.editor_config.enabled do return;

    if wb_plat.get_input(configs.key_config.camera_free_move) {
        wb.do_camera_movement(&wb.wb_camera, dt, Base_Speed, Base_Speed * 3, Base_Speed * 0.3);

        configs.editor_config.camera_position = wb.wb_camera.position;
        configs.editor_config.camera_rotation = wb.wb_camera.rotation;
    }

    /*if wb_plat.get_input_down(configs.key_config.editor_select) {
        mouse_world := wb.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
        mouse_direction := wb.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);

        hits := make([dynamic]RaycastHit, 0, 10);
        hit := raycast(wb.wb_camera.position, mouse_direction * 100, &hits);

        if hit > 0 {
            first_hit := hits[0];
            selected_entity= first_hit.e;
        }
    }*/

    if ecs.selected_entity != 0 {
        transform, ok := ecs.get_component(ecs.selected_entity, ecs.Transform);
        wb.gizmo_manipulate(&transform.position, &transform.scale, &transform.rotation);
    }
}

render :: proc() {
    if !configs.editor_config.enabled do return;

    transform, ok := ecs.get_component(ecs.selected_entity, ecs.Transform);
    if ok {
        wb.gizmo_render(transform.position, transform.scale, transform.rotation);
    }
}