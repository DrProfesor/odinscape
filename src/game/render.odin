package game

using import "core:fmt"

import wb    "shared:workbench"
import       "shared:workbench/gpu"
using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/types"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

shaders: map[string]gpu.Shader_Program;

init_render :: proc() {
    shaders["lit"] = wb.shader_texture_lit;
    shaders["skinned"] = wb.shader_skinned;
}

Model_Renderer :: struct {
    using base: Component_Base,
    model_id: string,
    texture_id: string,
    shader_id: string,
    color: Colorf,
    material: wb.Material,
    scale: Vec3,
}

init_model_renderer :: proc(using mr: ^Model_Renderer) {
	scale = Vec3{1, 1, 1};
	color = Colorf{1, 1, 1, 1};
	shader_id = "lit";
	material = wb.Material {
        {1, 0.5, 0.3, 1}, {1, 0.5, 0.3, 1}, {0.5, 0.5, 0.5, 1}, 32
    };
}

render_model_renderer :: proc(using mr: ^Model_Renderer) {
	tf, exists := get_component(e, Transform);
	if tf == nil {
		logln("Error: no transform for entity ", e);
		return;
	}
    
	model, ok := asset_catalog.models[model_id];
	if !ok {
		logln("Couldn't find model in catalog: ", model_id);
		return;
	}
    
	texture, tok := asset_catalog.textures[texture_id];
	if !tok {
		logln("Couldn't find texture in catalog: ", texture_id);
        return;
	}
    
    shader, sok := shaders[shader_id];
    assert(sok);
    
	wb.submit_model(model, shader, texture, material, tf.position, tf.scale * scale, tf.rotation,  color);
}