package game

import "core:fmt"

import wb "shared:wb"
import gpu "shared:wb/gpu"
import wb_plat  "shared:wb/platform"
import "shared:wb/math"
import "shared:wb/external/imgui"

import "../configs"
import "../physics"
import "../net"

wb_terrain: wb.Terrain;

get_terrain_height_at_position :: proc(pos: Vec3) -> f32 {
    p, _, hit := wb.raycast_into_terrain(wb_terrain, {0,0,0}, pos, Vec3{0, -1, 0});
    if hit { return p.y; }

    // TODO (jake): maybe we don't need to panic here
    // panic(fmt.tprint("Failed to find terrain height at position: ", pos));
    return 0;
}

init_terrain :: proc() {
    // TODO(jake): saving, maybe wb should handle that

    wb_terrain = wb.create_terrain({64,256,64}, 0.5);
	wb_terrain.material = wb.Material {
        0.5,0.5,0.5
    };
}

render_terrain :: proc() {
    when #config(HEADLESS, false) do return;
    else {
    
        wb.render_terrain(&wb_terrain, {0,0,0}, {1,1,1});
    }
}

editor_render_terrain :: proc() {
    when #config(HEADLESS, false) do return;
    else {
        wb.render_terrain_editor(&wb_terrain);
    }
}