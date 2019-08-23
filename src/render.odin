package main

using import "core:fmt"
using import "core:math"

import wb     "shared:workbench"
import        "shared:workbench/gpu"
using import        "shared:workbench/basic"
using import        "shared:workbench/logging"
using import        "shared:workbench/types"

Model_Renderer :: struct {
    using base: Component_Base,
    model_id: string,
    texture_id: string,
    shader: gpu.Shader_Program,
    color: Colorf,
    material: Material,
    scale: Vec3,
}

init_model_renderer :: proc(using mr: ^Model_Renderer) {
	scale = Vec3{1, 1, 1};
	color = Colorf{1, 1, 1, 1};
	shader = shader_texture_lit;
	material = Material {
        {1, 0.5, 0.3, 1}, {1, 0.5, 0.3, 1}, {0.5, 0.5, 0.5, 1}, 32
    };
}

render_model_renderer :: proc(using mr: ^Model_Renderer) {
	tf := em_get_component(e, Transform);
	if tf == nil {
		logln("Error: no transform for entity ", e);
		return;
	}

	if shader == 0 {
		logln("No shader, returning.");
		return;
	}

	model, ok := asset_catalog.models[model_id];
	if !ok {
		logln("Couldn't find model in catalog: ", model_id);
		return;
	}

	t, tok := asset_catalog.textures[texture_id];
	if !tok {
		t = {};
	}

	gpu.use_program(shader);
	gpu.rendermode_world();

    flush_lights_to_shader(shader);
	set_current_material(shader, material);
	gpu.draw_model(model, tf.position, tf.scale * scale, tf.rotation, t, color, true);
}