package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:workbench/gpu"
import wb    "shared:workbench"
import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/types"
import "shared:workbench/ecs"
import "shared:workbench/math"

Particle_Emitter :: struct {
    using base: ecs.Component_Base,

    base_emitter: wb.Particle_Emitter,
}

init_emitter :: proc(using emitter: ^Particle_Emitter) {
    wb.init_particle_emitter(&emitter.base_emitter, 1);
    base_emitter.shader = wb.get_shader(&wb.wb_catalog, "particle");
    base_emitter.emission = wb.Spheric_Emission{};
    
    //base_emitter.texture = wb.get_texture(&asset_catalog, "particle");
}

update_emitter :: proc(using emitter: ^Particle_Emitter, dt: f32) {
    t, ok := ecs.get_component(e, ecs.Transform);
    base_emitter.position = t.position;

    texture, ok2 := wb.try_get_texture(&asset_catalog, base_emitter.texture_id);
    if ok2 {
        base_emitter.texture = texture;
    }

    wb.update_particle_emitter(&emitter.base_emitter, dt);
}

render_emitters :: proc() {
    all_emitters := ecs.get_component_storage(Particle_Emitter);
    for _, i in all_emitters {
        render_emitter(&all_emitters[i]);
    }
}

render_emitter :: proc(using emitter: ^Particle_Emitter) {

	projection_matrix := wb.construct_rendermode_matrix(wb.current_camera);
	view_matrix := wb.construct_view_matrix(wb.current_camera);

    wb.render_particle_emitter(&emitter.base_emitter, projection_matrix, view_matrix);
    
}