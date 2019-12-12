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

import p "shared:workbench/particles"

Particle_Emitter :: struct {
    using base: Component_Base,
    
    base_emitter: p.Particle_Emitter,
}

init_emitter :: proc(using emitter: ^Particle_Emitter) {
    p.init_particle_emitter(&emitter.base_emitter, 1);
}

update_emitter :: proc(using emitter: ^Particle_Emitter, dt: f32) {
    p.update_particle_emitter(&emitter.base_emitter, dt);
}

render_emitter :: proc(using emitter: ^Particle_Emitter) {
    p.render_particle_emitter(&emitter.base_emitter);
}