package game

import "core:fmt"

import wb "shared:wb"
import gpu "shared:wb/gpu"
import wb_plat  "shared:wb/platform"
import "shared:wb/ecs"
import "shared:wb/math"
import "shared:wb/external/imgui"

import "../configs"
import "../physics"
import "../net"

get_terrain_height_at_position :: proc(pos: Vec3) -> f32 {
	terrains := ecs.get_component_storage(Terrain);
    for terrain in terrains {
        terrain_transform, ok := ecs.get_component(terrain.e, ecs.Transform);
        pos, _, hit := wb.raycast_into_terrain(terrain, terrain_transform.position, pos, Vec3{0, -1, 0});
        if hit {
            return pos.y;
        }
    }

    // TODO (jake): maybe we don't need to panic here
    // panic(fmt.tprint("Failed to find terrain height at position: ", pos));
    return 0;
}

Terrain :: struct {
    using base: ecs.Component_Base,
    using wb_terrain: wb.Terrain "wbml_noserialize",
}

mul : f32 = 9;

init_terrain :: proc(using tr: ^Terrain) {
    if math.magnitude(chunk_size) == 0 do chunk_size = {64,256,64};

    // TODO(jake): saving, maybe wb should handle that

    wb_terrain = wb.create_terrain(chunk_size, 0.5);
	material = wb.Material {
        0.5,0.5,0.5
    };

    // for i in 0..20 {
    //     u := spiral(i);
    //     offset := Vec3{u.x, 0, u.y} * (wb_terrain.chunk_size - (wb.CHUNK_CREATION_DISTANCE+2)/wb_terrain.step);
    //     // offset -= Vec3{u.x, 0, u.y} * Vec3{wb.CHUNK_CREATION_DISTANCE+2, 0, wb.CHUNK_CREATION_DISTANCE+2};
    //     wb.add_terrain_chunk(&wb_terrain, wb.create_default_density_map(wb_terrain.chunk_size), offset);
    // }
}

spiral :: proc(n: int) -> Vec2 {
    k := math.ceil((math.sqrt(f32(n))-1)/2);
    t := 2 * k + 1;
    m := t * t;
    t = t-1;
    if f32(n) >= m-t do return {k-(m-f32(n)), -k}; else do m=m-t;
    if f32(n) >= m-t do return {-k, -k+(m-f32(n))}; else do m=m-t;
    if f32(n) >= m-t do return {-k+(m-f32(n)), k} else do return {k,k-(m-f32(n)-t)};
}

render_terrain :: proc(using tr: ^Terrain) {
    when #config(HEADLESS, false) do return;
    else {
        tf, exists := ecs.get_component(e, ecs.Transform);
        if tf == nil {
            logln("Error: no transform for entity ", e);
            return;
        }

    
        wb.render_terrain(&wb_terrain, tf.position, tf.scale);
    }
}

editor_render_terrain :: proc(using tr: ^Terrain) {
    when #config(HEADLESS, false) do return;
    else {
        wb.render_terrain_editor(&wb_terrain);
    }
}