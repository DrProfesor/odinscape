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

import p "shared:workbench/particles"

Particle_Emitter :: struct {
    using base: Component_Base,
    
    base_emitter: p.Particle_Emitter,
}

init_emitter :: proc(using emitter: ^Particle_Emitter) {
    p.init_particle_emitter(&emitter.base_emitter, 1);
    base_emitter.shader = wb.get_shader(&wb.wb_catalog, "particle");
    base_emitter.emission = p.Spheric_Emission{Vec3{0,1,0}, -45, 45};
}

update_emitter :: proc(using emitter: ^Particle_Emitter, dt: f32) {
    t, ok := get_component(e, Transform);
    base_emitter.position = t.position;
    p.update_particle_emitter(&emitter.base_emitter, dt);
}

render_emitter :: proc(using emitter: ^Particle_Emitter) {
    
	projection_matrix := wb.construct_rendermode_matrix(wb.current_camera);
	view_matrix := wb.construct_view_matrix(wb.current_camera);
    
    p.render_particle_emitter(&emitter.base_emitter, projection_matrix, view_matrix);
    
    for particle in base_emitter.particles {
        if particle.dead do continue;
        wb.draw_debug_box(particle.position, Vec3{0.05,0.05,0.05}, Colorf{1,0,0,1});
    }
}