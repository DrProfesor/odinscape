package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:wb/gpu"
import wb    "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/types"
import "shared:wb/math"

// Particle_Emitter :: struct {
//     using base: ecs.Component_Base,

//     base_emitter: wb.Particle_Emitter,
// }

// init_emitter :: proc(using emitter: ^Particle_Emitter) {
//     wb.init_particle_emitter(&emitter.base_emitter, 1);
//     base_emitter.shader = wb.get_shader("particle");
//     base_emitter.emission = wb.Spheric_Emission{};

//     //base_emitter.texture = wb.get_texture(&asset_catalog, "particle");
// }

// update_emitter :: proc(using emitter: ^Particle_Emitter, dt: f32) {
//     t, ok := ecs.get_component(e, ecs.Transform);
//     base_emitter.position = t.position;

//     texture, ok2 := wb.try_get_texture(base_emitter.texture_id);
//     if ok2 {
//         base_emitter.texture = texture;
//     }

//     wb.update_particle_emitter(&emitter.base_emitter, dt);
// }

// render_emitters :: proc() {
//     all_emitters := ecs.get_component_storage(Particle_Emitter);
//     for _, i in all_emitters {
//         render_emitter(&all_emitters[i]);
//     }
// }

// render_emitter :: proc(using emitter: ^Particle_Emitter) {

// 	projection_matrix := wb.construct_rendermode_projection_matrix(wb.main_camera);
// 	view_matrix := wb.construct_view_matrix(wb.main_camera);

//     wb.render_particle_emitter(&emitter.base_emitter, projection_matrix, view_matrix);

// }