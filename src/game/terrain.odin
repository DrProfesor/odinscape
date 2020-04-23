package game

import "core:fmt"

import wb "shared:workbench"
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
    shader_id: string,
    
}

init_terrain :: proc(using tr: ^Terrain) {
    when SERVER do return;
    else {
        height_map := make([dynamic][]f32, 0, 128);
        for x in 0..128 {
            hm:= make([dynamic]f32, 0, 128);
            for z in 0..128 {
                append(&hm, 0);
                //append(&hm, math.get_noise(x, z, 11230978, 0.01, 1, 0.25));
            }
            
            append(&height_map, hm[:]);
        }
        
        wb_terrain = wb.create_terrain(128, height_map[:]);
        shader_id = "terrain";
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
        
        shader := wb.get_shader(shader_id);
        
        cmd := wb.create_draw_command(wb_terrain.model, shader, tf.position, tf.scale, tf.rotation, {1,1,1,1}, {}, material);
        wb.submit_draw_command(cmd);
    }
}