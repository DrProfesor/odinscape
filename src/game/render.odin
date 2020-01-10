package game

import "core:fmt"

import wb "shared:workbench"
import "shared:workbench/gpu"
import "shared:workbench/basic"
import log "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"

import "shared:workbench/external/stb"

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
	scale = math.Vec3{1, 1, 1};
	color = types.Colorf{1, 1, 1, 1};
	shader_id = "lit";
	material = wb.Material {
        {1, 0.5, 0.3, 1}, {1, 0.5, 0.3, 1}, {0.5, 0.5, 0.5, 1}, 32
    };
}

render_model_renderer :: proc(using mr: ^Model_Renderer) {
	tf, exists := ecs.get_component(e, ecs.Transform);
	if tf == nil {
		log.ln("Error: no transform for entity ", e);
		return;
	}
    
	model, ok := wb.try_get_model(&asset_catalog, model_id);
	if !ok {
		log.ln("Couldn't find model in catalog: ", model_id);
		return;
	}
    
	texture, tok := wb.try_get_texture(&asset_catalog, texture_id);
	if !tok {
		log.ln("Couldn't find texture in catalog: ", texture_id);
        return;
	}
    
    anim_state : wb.Model_Animation_State = {};
    animator, aok := ecs.get_component(e, Animator);
    if aok {
        anim_state = animator.animation_state;
    }
    
    shader := wb.get_shader(&asset_catalog, shader_id);
    
	wb.submit_model(model, shader, texture, material, tf.position, tf.scale * scale, tf.rotation,  color, anim_state);
}

// terrain

Terrain :: struct {
    using base: ecs.Component_Base,
    
    wb_terrain: wb.Terrain,
    material: wb.Material,
    shader_id: string,
    
}

init_terrain :: proc(using tr: ^Terrain) {
    height_map := make([dynamic][]f32, 0, 128);
    for x in 0..128 {
        hm:= make([dynamic]f32, 0, 128);
        for z in 0..128 {
            append(&hm, math.get_noise(x, z, 11230978, 0.1, 1, 1));
        }
        
        append(&height_map, hm[:]);
    }
    
    wb_terrain = wb.create_terrain(128, height_map[:]);
    shader_id = "terrain";
	material = wb.Material {
        {1, 0.5, 0.3, 1}, {1, 0.5, 0.3, 1}, {0.5, 0.5, 0.5, 1}, 32
    };
    
}

update_terrain :: proc(using tr: ^Terrain) {
    if !wb.debug_window_open do return;
    
    
}

render_terrain :: proc(using tr: ^Terrain) {
    tf, exists := ecs.get_component(e, ecs.Transform);
	if tf == nil {
		log.ln("Error: no transform for entity ", e);
		return;
	}
    
    shader := wb.get_shader(&asset_catalog, shader_id);
    
    wb.submit_model(wb_terrain.model, shader, {}, material, tf.position, tf.scale, tf.rotation, {1,1,1,1}, {});
}