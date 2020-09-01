package game

import "core:fmt"
import "core:mem"
import "core:os"

import wb "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/types"
import "shared:wb/ecs"
import "shared:wb/math"

import "shared:wb/external/imgui"

// init_animator :: proc(using animator: ^Animator) {
//     mr, mr_exists := ecs.get_component(e, Model_Renderer);
//     model, ok := wb.try_get_model(mr.model_id);
//     wb.init_animation_player(&controller.player, model);
// }

// update_animator :: proc(using animator: ^Animator, dt: f32) {
//     when #config(HEADLESS, false) do return;
//     else {
//         // TODO if dev build
//         if open_animator_window {
//             wb.draw_animation_controller_window(&controller, &open_animator_window);
//         }

//         mr, mr_exists := ecs.get_component(e, Model_Renderer);
//         model, ok := wb.try_get_model(mr.model_id);
//         if previous_mesh_id != mr.model_id {
//             wb.init_animation_player(&controller.player, model);
//             previous_mesh_id = mr.model_id;
//         }

//         wb.tick_animation(&controller.player, model, dt);
//     }
// }

// editor_render_animator :: proc(using animator: ^Animator) {
//     when #config(HEADLESS, false) do return;
//     else {
//         if imgui.collapsing_header("Animator") {
//             if imgui.button("Open") do open_animator_window = true;
//         }
//     }
// }

// // @requires Model_Renderer
// Animator :: struct {
//     using base: ecs.Component_Base,

//     controller: wb.Animation_Controller,
//     previous_mesh_id: string,
//     open_animator_window: bool,
// }