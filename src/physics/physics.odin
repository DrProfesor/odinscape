package main

using import "core:math"
using import "core:fmt"
using import "core:runtime"

using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"

using import wb_ecs "shared:workbench/ecs"
import wb_col  "shared:workbench/collision"
import wb_plat "shared:workbench/platform"
import wb      "shared:workbench"

DEBUG :: true;

collision_scene : wb_col.Collision_Scene;
internal_hits : [dynamic]wb_col.Hit_Info;

Collider :: struct {
    using base : Component_Base,
    internal_collider : wb_col.Collider "wbml_unserialized, imgui_hidden",
    type : Collider_Type,
    box: wb_col.Box,
}

Collider_Type :: enum {
    Box,
}

RaycastHit :: struct {
    e: Entity,
    intersection_start: Vec3,
    intersection_stop: Vec3,
    
    //TODO
    //normal: Vec3,
}

init_collider :: proc(using col : ^Collider) {
    
    entity_transform, ok := get_component(e, Transform);
    
    col.internal_collider = wb_col.Collider {
        entity_transform.position,
        box
    };
    
    wb_col.add_collider_to_scene(&collision_scene, internal_collider, e);
}

update_collider :: proc(using col : ^Collider, dt : f32) {
    entity_transform, ok := get_component(e, Transform);
    
    internal_collider = wb_col.Collider {
        entity_transform.position,
        box
    };
    
    wb_col.update_collider(&collision_scene, e, internal_collider);
}

render_collider :: proc(using col : ^Collider) {
    if !DEBUG do return;
    
    entity_transform, ok := get_component(e, Transform);
    wb.draw_debug_box(entity_transform.position, col.box.size, COLOR_GREEN);
}

raycast :: proc(start : Vec3, direction : Vec3, hits : ^[dynamic]RaycastHit) -> int {
    clear(&internal_hits);
    
    wb_col.linecast(&collision_scene, start, direction, &internal_hits);
    
    for internal_hit in internal_hits {
        append(hits, RaycastHit{ Entity(internal_hit.handle), internal_hit.point0, internal_hit.point1  });
    }
    
    return len(internal_hits);
}