package game

import "core:fmt"

import wb "shared:wb"
import "shared:wb/gpu"
import "shared:wb/basic"
import log "shared:wb/logging"
import "shared:wb/types"
import "shared:wb/ecs"
import "shared:wb/math"

import "shared:wb/external/stb"

Model_Renderer :: struct {
    using base: ecs.Component_Base,
    model_id: string,
    texture_id: string,
    shader_id: string,
    color: types.Colorf,
    material: wb.Material,
    scale: math.Vec3,
}

init_model_renderer :: proc(using mr: ^Model_Renderer) {
    when #config(HEADLESS, false) do return;
    else {
        scale = math.Vec3{1, 1, 1};
        color = types.Colorf{1, 1, 1, 1};
        shader_id = "lit";
        material = wb.Material {
            0.5, 0.5, 0.5
        };
    }
}

render_model_renderer :: proc(using mr: ^Model_Renderer) {
    when #config(HEADLESS, false) do return;
    else {
    	tf, exists := ecs.get_component(e, ecs.Transform);
    	if tf == nil {
    		log.logln("Error: no transform for entity ", e);
    		return;
    	}
        
    	model, ok := wb.try_get_model(model_id);
    	if !ok {
    		log.logln("Couldn't find model in catalog: ", model_id);
    		return;
    	}
        
    	texture, tok := wb.try_get_texture(texture_id);
    	if !tok {
    		log.logln("Couldn't find texture in catalog: ", texture_id);
            return;
    	}
        
        anim_state : wb.Model_Animation_State = {};
        animator, aok := ecs.get_component(e, Animator);
        if aok {
            anim_state = animator.animation_state;
        }
        
        shader := wb.get_shader(shader_id);
        
    	cmd := wb.create_draw_command(model, shader, tf.position, tf.scale * scale, tf.rotation,  color, material, texture); // anim_state
        cmd.anim_state = anim_state;
        wb.submit_draw_command(cmd);
    }
}