package game

import "core:fmt"

import wb "shared:workbench"
import gpu "shared:workbench/gpu"
import "shared:workbench/ecs"
import "shared:workbench/math"

import "../configs"
import "../physics"
import "../net"
import "../shared"

get_terrain_height_at_position :: proc(pos: Vec2) -> f32 {
	terrains := ecs.get_component_storage(Terrain);
    for terrain in terrains {
        terrain_transform, ok := ecs.get_component(terrain.e, ecs.Transform);
        h, ok1 := wb.get_height_at_position(terrain.wb_terrain, terrain_transform.position, pos.x, pos.y);
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
    
    wb_terrain: wb.Terrain "wbml_noserialize",
    material: wb.Material,    
}

init_terrain :: proc(using tr: ^Terrain) {
    when SERVER do return;
    else {
        density_map := make([][][]f32, 32);
        for x in 0..<32 {
            hm1 := make([][]f32, 32);
            for y in 0..<32 {
                hm2 := make([]f32, 32);
                for z in 0..<32 {
                    hm2[z] = -(f32(y)-2);
                }
                hm1[y] = hm2;
            }
        
            density_map[x] = hm1;
        }
        
        wb_terrain = wb.create_terrain(density_map[:]);
    	material = wb.Material {
            0.5,0.5,0.5
        };
    }
}

update_terrain :: proc(using tr: ^Terrain) {
    if !wb.debug_window_open do return;
    
    
}

render_terrain :: proc(using tr: ^Terrain) {
    when SERVER do return;
    else {
        tf, exists := ecs.get_component(e, ecs.Transform);
    	if tf == nil {
    		logln("Error: no transform for entity ", e);
    		return;
    	}
        wb.render_terrain(&wb_terrain, tf.position, tf.scale, material);
    }
}