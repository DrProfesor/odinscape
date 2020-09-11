package physics

import "core:fmt"
import "core:runtime"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/collision"
import "shared:wb"

DEBUG :: true;

RaycastHit :: struct {

}

// init_collider :: proc(using col : ^Collider) {
//     entity_transform, ok := wb_ecs.get_component(e, wb_ecs.Transform);
//     col.internal_collider = wb_col.add_collider_to_scene(&collision_scene, entity_transform.position, {1,1,1}, { {}, box }, transmute(rawptr) e);
// }

// update_collider :: proc(using col : ^Collider, dt : f32) {
//     entity_transform, ok := wb_ecs.get_component(e, wb_ecs.Transform);
//     wb_col.update_collider(internal_collider, entity_transform.position, {1,1,1}, { {}, box }, transmute(rawptr) e);
// }

// render_collider :: proc(using col : ^Collider) {
//     if !DEBUG do return;

//     entity_transform, ok := wb_ecs.get_component(e, wb_ecs.Transform);
//     wb.draw_debug_box(entity_transform.position, col.box.size, types.COLOR_GREEN);
// }

overlap_point :: proc(point: Vector3, hits: ^[dynamic]RaycastHit = nil) -> int {
    // clear(&internal_hits);

    // wb_col.overlap_point(&collision_scene, point, &internal_hits);

    // if hits != nil {
    //     for internal_hit in internal_hits {
    //         append(hits, RaycastHit{ wb_ecs.Entity(transmute(int)internal_hit.userdata), internal_hit.point0, internal_hit.point1  });
    //     }
    // }

    // return len(internal_hits);

    return 0;
}

raycast :: proc(start, direction : Vector3, hits : ^[dynamic]RaycastHit = nil) -> int {
    // clear(&internal_hits);

    // wb_col.linecast(&collision_scene, start, direction, &internal_hits);

    // if hits != nil {
    //     for internal_hit in internal_hits {
    //         append(hits, RaycastHit{ wb_ecs.Entity(transmute(int)internal_hit.userdata), internal_hit.point0, internal_hit.point1  });
    //     }
    // }

    // return len(internal_hits);

    return 0;
}