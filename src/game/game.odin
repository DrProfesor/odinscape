package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/math"

import "shared:workbench/ecs"
import wb "shared:workbench"
import wb_gpu "shared:workbench/gpu"

import "../shared"
import "../configs"

asset_catalog: wb.Asset_Catalog;
prefab_scene: ecs.Prefab_Scene;

game_init :: proc() {

	when !SERVER {
		wb.load_asset_folder("resources", &asset_catalog);
	}
 
	// camera
	when !SERVER {
		wb.main_camera.is_perspective = true;
		wb.main_camera.size = 70;
		wb.main_camera.position = math.Vec3{0, 6.09, 4.82};
		wb.main_camera.rotation = math.Quat{0,0,0,1};
	}

	when !SERVER {
		wb.init_particles();
	}
     
    // entities
	{
		scene_init("main");
		prefab_scene = ecs.load_prefab_dir("resources/Prefabs");
	}
}

game_update :: proc(dt: f32) {
	ecs.update(dt);

    if wb.debug_window_open do return;

    update_camera(dt);
}

game_render :: proc() {
	ecs.render();
}

game_end :: proc() {
	scene_end("main");

	wb.delete_asset_catalog(asset_catalog);
}

logln :: logging.logln;