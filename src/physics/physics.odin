package physics

import "core:fmt"
import "core:runtime"

import    "shared:workbench/types"
import    "shared:workbench/basic"
import    "shared:workbench/logging"
import    "shared:workbench/math"

import wb_ecs "shared:workbench/ecs"
import wb_col  "shared:workbench/collision"
import wb_plat "shared:workbench/platform"
import wb      "shared:workbench"

DEBUG :: true;

collision_scene : wb_col.Collision_Scene;
internal_hits : [dynamic]wb_col.Hit_Info;

Collider :: struct {
    using base : wb_ecs.Component_Base,
    internal_collider : wb_col.Collider "wbml_unserialized, imgui_hidden",
    type : Collider_Type,
    box: wb_col.Box,
}

Collider_Type :: enum {
    Box,
}

RaycastHit :: struct {
    e: wb_ecs.Entity,
    intersection_start: Vec3,
    intersection_stop: Vec3,

    //TODO
    //normal: Vec3,
}

init_collider :: proc(using col : ^Collider) {

    entity_transform, ok := wb_ecs.get_component(e, wb_ecs.Transform);

    col.internal_collider = wb_col.Collider {
        entity_transform.position,
        box
    };

    wb_col.add_collider_to_scene(&collision_scene, internal_collider, e);
}

update_collider :: proc(using col : ^Collider, dt : f32) {
    entity_transform, ok := wb_ecs.get_component(e, wb_ecs.Transform);

    internal_collider = wb_col.Collider {
        entity_transform.position,
        box
    };

    wb_col.update_collider(&collision_scene, e, internal_collider);
}

render_collider :: proc(using col : ^Collider) {
    if !DEBUG do return;

    entity_transform, ok := wb_ecs.get_component(e, wb_ecs.Transform);
    wb.draw_debug_box(entity_transform.position, col.box.size, types.COLOR_GREEN);
}

overlap_point :: proc(point: Vec3, hits: ^[dynamic]RaycastHit = nil) -> int {
    clear(&internal_hits);

    wb_col.overlap_point(&collision_scene, point, &internal_hits);

    if hits != nil {
        for internal_hit in internal_hits {
            append(hits, RaycastHit{ wb_ecs.Entity(internal_hit.handle), internal_hit.point0, internal_hit.point1  });
        }
    }

    return len(internal_hits);
}

raycast :: proc(start : Vec3, direction : Vec3, hits : ^[dynamic]RaycastHit = nil) -> int {
    clear(&internal_hits);

    wb_col.linecast(&collision_scene, start, direction, &internal_hits);

    if hits != nil {
        for internal_hit in internal_hits {
            append(hits, RaycastHit{ wb_ecs.Entity(internal_hit.handle), internal_hit.point0, internal_hit.point1  });
        }
    }

    return len(internal_hits);
}



Vec2 :: math.Vec2;
Vec3 :: math.Vec3;
distance :: math.distance;