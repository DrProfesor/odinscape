package game

using import "core:fmt"
import       "core:mem"
import       "core:os"

import "shared:workbench/gpu"
import wb    "shared:workbench"
using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/types"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

Particle_Emitter :: struct {
    using base: Component_Base,
    
    base_emitter: wb.Particle_Emitter,
}

init_emitter :: proc(using emitter: ^Particle_Emitter) {
    wb.init_particle_emitter(&emitter.base_emitter, 1);
    base_emitter.shader = wb.get_shader(&wb.wb_catalog, "particle");
    base_emitter.emission = wb.Spheric_Emission{};
    
    //base_emitter.texture = wb.get_texture(&asset_catalog, "particle");
}

update_emitter :: proc(using emitter: ^Particle_Emitter, dt: f32) {
    t, ok := get_component(e, Transform);
    base_emitter.position = t.position;
    
    texture, ok2 := wb.try_get_texture(&asset_catalog, base_emitter.texture_id);
    if ok2 {
        base_emitter.texture = texture;
    }
    
    wb.update_particle_emitter(&emitter.base_emitter, dt);
}

render_emitters :: proc() {
    all_emitters := get_component_storage(Particle_Emitter);
    for _, i in all_emitters {
        render_emitter(&all_emitters[i]);
    }
}

render_emitter :: proc(using emitter: ^Particle_Emitter) {
    
	projection_matrix := wb.construct_rendermode_matrix(wb.current_camera);
	view_matrix := wb.construct_view_matrix(wb.current_camera);
    
    wb.render_particle_emitter(&emitter.base_emitter, projection_matrix, view_matrix);
    
}