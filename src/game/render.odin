package game

import "core:fmt"

import wb "shared:workbench"
import "shared:workbench/gpu"
import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"


init_render :: proc() {
}

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
		logging.ln("Error: no transform for entity ", e);
		return;
	}

	model, ok := wb.try_get_model(&asset_catalog, model_id);
	if !ok {
		logging.ln("Couldn't find model in catalog: ", model_id);
		return;
	}

	texture, tok := wb.try_get_texture(&asset_catalog, texture_id);
	if !tok {
		logging.ln("Couldn't find texture in catalog: ", texture_id);
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