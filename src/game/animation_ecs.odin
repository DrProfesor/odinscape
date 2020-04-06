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

import anim  "shared:workbench/animation"
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

        model, model_exists := wb.try_get_model(&asset_catalog, mr.model_id);
        if !model_exists {
            logging.logln("Couldn't find model in catalog: ", mr.model_id);
            return;
        } else {
            if previous_mesh_id != mr.model_id {
                animation_state.mesh_states =  make([dynamic]wb.Mesh_State, 0, len(model.meshes));
                for i:=0; i < len(model.meshes); i += 1 {
                    arr := make([dynamic]math.Mat4, 0, len(model.meshes[i].skin.bones));

                    for bone in model.meshes[i].skin.bones {
                        append(&arr, bone.offset);
                    }

                    append(&animation_state.mesh_states, wb.Mesh_State { arr });
                }
            }
        }

        if current_animation in anim.loaded_animations {
            animation := anim.loaded_animations[current_animation];

            running_time += dt;

            tps : f32 = 25.0;
            if animation.ticks_per_second != 0 {
                tps = animation.ticks_per_second;
            }
            time_in_ticks := running_time * tps;
            time = math.mod(time_in_ticks, animation.duration);
        }

        for mesh, i in model.meshes {
            anim.get_animation_data(mesh, current_animation, time, &animation_state.mesh_states[i].state);
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

            available_anims := anim.get_animations_for_target(mr.model_id);
            if imgui.list_box_header("Animations") {
                for aa, i in available_anims {
                    if imgui.selectable(aa, aa == current_animation) {
                        current_animation = aa;

                    }
                }
                imgui.list_box_footer();
            }

            current_animation_data := anim.loaded_animations[current_animation];
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