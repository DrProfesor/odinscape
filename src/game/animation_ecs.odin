package game

using import "core:fmt"
import       "core:mem"
import       "core:os"

import wb    "shared:workbench"
using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/types"
using import "shared:workbench/ecs"
using import "shared:workbench/math"
import anim  "shared:workbench/animation"

init_animator :: proc(using animator: ^Animator) {
    mr, mr_exists := get_component(e, Model_Renderer);
    if !mr_exists {
        logln("No model renderer found on entity ", e);
        return;
    }
    
    model, model_exists := asset_catalog.models[mr.model_id];
	if !model_exists {
		logln("Couldn't find model in catalog: ", mr.model_id);
		return;
	}
    
    // TODO destroy
    logln(len(model.meshes));
    animation_state.mesh_states =  make([dynamic]wb.Mesh_State, 0, len(model.meshes));
    for i:=0; i < len(model.meshes); i += 1 {
        arr := make([dynamic]Mat4, 0, len(model.meshes[i].skin.bones));
        
        for bone in model.meshes[i].skin.bones {
            append(&arr, bone.offset);
        }
        
        append(&animation_state.mesh_states, wb.Mesh_State { arr });
    }
}

update_animator :: proc(using animator: ^Animator, dt: f32) {
    mr, mr_exists := get_component(e, Model_Renderer);
    if !mr_exists {
        logln("No model renderer found on entity ", e);
        return;
    }
    
    model, model_exists := asset_catalog.models[mr.model_id];
    if !model_exists {
        logln("Couldn't find model in catalog: ", mr.model_id);
        return;
    }
    
    if current_animation in anim.loaded_animations {
        animation := anim.loaded_animations[current_animation];
        
        running_time += dt;
        
        tps : f32 = 25.0;
        if animation.ticks_per_second != 0 {
            tps = animation.ticks_per_second;
        }
        time_in_ticks := running_time * tps;
        time = mod(time_in_ticks, animation.duration);
    }
    
    for mesh, i in model.meshes {
        anim.get_animation_data(mesh, current_animation, time, &animation_state.mesh_states[i].state);
    }
}

// @requires Model_Renderer
Animator :: struct {
    using base: Component_Base,
    
    animation_state: wb.Model_Animation_State,
    
    time: f32,
    current_animation: string,
    running_time: f32,
}