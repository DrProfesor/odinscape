package game

import "core:fmt"
import "core:mem"
import "core:os"

import wb "shared:workbench"
import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"

import "shared:workbench/external/imgui"

init_animator :: proc(using animator: ^Animator) {
}

update_animator :: proc(using animator: ^Animator, dt: f32) {
    when SERVER do return;
    else {
        mr, mr_exists := ecs.get_component(e, Model_Renderer);
        if !mr_exists {
            logging.logln("No model renderer found on entity ", e);
            return;
        }

        model, model_exists := wb.try_get_model(mr.model_id);
        assert(model_exists);

        if previous_mesh_id != mr.model_id {
            animation_state.mesh_states =  make([]wb.Mesh_State, len(model.meshes));
            for i:=0; i < len(model.meshes); i += 1 {
                arr := make([]Mat4, len(model.meshes[i].skin.offsets));

                for bone, j in model.meshes[i].skin.offsets {
                    arr[j] = bone;
                }

                animation_state.mesh_states[i] = wb.Mesh_State { arr };
            }
        }

        if current_animation in wb.loaded_animations {
            animation := wb.loaded_animations[current_animation];

            running_time += dt;

            tps : f32 = 25.0;
            if animation.ticks_per_second != 0 {
                tps = animation.ticks_per_second;
            }
            time_in_ticks := running_time * tps;
            time = math.mod(time_in_ticks, animation.duration);
        }

        for mesh, i in model.meshes {
            wb.sample_animation(mesh, current_animation, time, &animation_state.mesh_states[i].state);
        }
    }
}

editor_render_animator :: proc(using animator: ^Animator) {
    when SERVER do return;
    else {
        if imgui.collapsing_header("Animator") {
            imgui.indent();

            mr, mr_exists := ecs.get_component(e, Model_Renderer);
            if !mr_exists {
                imgui.label_text("INVALID", "INVALID");
                return;
            }

            available_anims := wb.get_animations_for_target(mr.model_id);
            if imgui.list_box_header("Animations") {
                for aa, i in available_anims {
                    if imgui.selectable(aa, aa == current_animation) {
                        current_animation = aa;

                    }
                }
                imgui.list_box_footer();
            }

            current_animation_data := wb.loaded_animations[current_animation];
            imgui.label_text("Running Time", fmt.tprint(time, " / ", current_animation_data.duration));

            defer imgui.unindent();
        }
    }
}

// @requires Model_Renderer
Animator :: struct {
    using base: ecs.Component_Base,

    animation_state: wb.Model_Animation_State,

    time: f32,
    current_animation: string,
    running_time: f32,

    previous_mesh_id: string,
}