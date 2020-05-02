package game

import "core:fmt"

import wb "shared:workbench"
import gpu "shared:workbench/gpu"
import wb_plat  "shared:workbench/platform"
import "shared:workbench/ecs"
import "shared:workbench/math"
import "shared:workbench/external/imgui"

import "../configs"
import "../physics"
import "../net"
import "../shared"

get_terrain_height_at_position :: proc(pos: Vec3) -> f32 {
	terrains := ecs.get_component_storage(Terrain);
    for terrain in terrains {
        terrain_transform, ok := ecs.get_component(terrain.e, ecs.Transform);
        h, ok1 := wb.get_height_at_position(terrain.wb_terrain, terrain_transform.position, pos.x, pos.z, pos.y);
        if ok1 {
            return h;
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

init_terrain :: proc(using tr: ^Terrain) {
    if math.magnitude(size) == 0 do size = {128,128,128};

    // TODO load density map
    _density_map := make([][][]f32, int(size.x));
    for x in 0..<int(size.x) {
        hm1 := make([][]f32, int(size.z));
        for z in 0..<int(size.z) {
            hm2 := make([]f32, int(size.y));
            for y in 0..<int(size.y) {
                hm2[y] = -(f32(y-2));
            }
            hm1[z] = hm2;
        }
    
        _density_map[x] = hm1;
    }
    
    wb_terrain = wb.create_terrain(_density_map, 1);
	material = wb.Material {
        0.5,0.5,0.5
    };
}

render_terrain :: proc(using tr: ^Terrain) {
    tf, exists := ecs.get_component(e, ecs.Transform);
    if tf == nil {
        logln("Error: no transform for entity ", e);
        return;
    }

    when SERVER do return;
    else {
        wb.render_terrain(&wb_terrain, tf.position, tf.scale);
    }
}

editor_render_terrain :: proc(using tr: ^Terrain) {
    wb.render_terrain_editor(&wb_terrain);
}