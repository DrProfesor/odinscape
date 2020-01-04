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

DEVELOPER :: true;

asset_catalog: wb.Asset_Catalog;
prefab_scene: ecs.Prefab_Scene;

game_init :: proc() {

	{
		// NOTE TO JAKE
		// the asset system no longer takes a list of file extensions to just read as text for you to query and do whatever with
		// you'll have to make a custom handler by calling wb.add_asset_handler() which is in wb assets.odin
		// wb.load_asset_folder("resources", &asset_catalog, "material", "txt", "e");

		wb.load_asset_folder("resources", &asset_catalog);
	}

	// camera
	{
		wb.wb_camera.is_perspective = true;
		wb.wb_camera.size = 70;
		wb.wb_camera.position = math.Vec3{0, 6.09, 4.82};
		wb.wb_camera.rotation = math.Quat{0,0,0,1};
	}

    wb.init_particles();

    // entities
	{
		scene_init("main");
		prefab_scene = ecs.load_prefab_dir("resources/prefabs");
	}

    when DEVELOPER {
        p := ecs.make_entity("Player");
        pe := ecs.add_component(p, shared.Player_Entity);
    }
}

game_update :: proc(dt: f32) {
	ecs.update(dt);

    if configs.editor_config.enabled do return;

    update_camera(dt);
}

game_render :: proc() {
	ecs.render();
}

game_end :: proc() {
	scene_end("main");

	wb.delete_asset_catalog(asset_catalog);
}