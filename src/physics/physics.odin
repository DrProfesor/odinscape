package physics

import "core:fmt"
import "core:runtime"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb"

import "../entity"
import "../shared"

update_physics :: proc(dt: f32) {
    for collider in &shared.g_collision_scene.colliders {
        if collider.userdata == nil do continue;

        entity := cast(^entity.Entity) collider.userdata;
        wb.update_collider(collider, entity.position, entity.scale, collider.info, entity);
    }
}

Raycast_Hit :: struct {
    hit_pos: Vector3,
    entity: ^entity.Entity,
}

wb_hits: [dynamic]wb.Hit_Info;

raycast :: proc(origin, direction: Vector3, hits: ^[dynamic]Raycast_Hit = nil) -> int {
    wb.linecast(&shared.g_collision_scene, origin, direction, &wb_hits);


    if hits != nil do for wb_hit in wb_hits {
        append(hits, Raycast_Hit{
            wb_hit.point0,
            cast(^entity.Entity) wb_hit.collider.userdata
        });
    }

    return len(wb_hits);
}