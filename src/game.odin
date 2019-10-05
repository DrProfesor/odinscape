package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"
import "shared:workbench/ecs"
import wb        "shared:workbench"
import wb_gpu    "shared:workbench/gpu"

import "physics"

DEVELOPER :: true;

asset_catalog: wb.Asset_Catalog;
shader_texture_lit: wb_gpu.Shader_Program;

game_init :: proc() {

	{
		wb.load_asset_folder("resources", &asset_catalog, "material", "txt", "e");
	}

	// shaders
	{
		ok: bool;
		shader_texture_lit, ok = wb_gpu.load_shader_text(SHADER_TEXTURE_LIT_VERT, SHADER_TEXTURE_LIT_FRAG);
		assert(ok);
	}

	// camera
	{
		wb.wb_camera.is_perspective = true;
		wb.wb_camera.size = 70;
		wb.wb_camera.position = Vec3{0, 6.09, 4.82};
		wb.wb_camera.rotation = Quat{0,0,0,1};
	}

    // entities
	{
		using ecs;
		add_component_type(Transform, nil, nil);
		add_component_type(Model_Renderer, nil, render_model_renderer, init_model_renderer);
        add_component_type(physics.Collider,
                           physics.update_collider, physics.render_collider, physics.init_collider);

		scene_init("main");
	}
}

game_update :: proc(dt: f32) {
	ecs.update(dt);
}

game_render :: proc() {
	ecs.render();
}

game_end :: proc() {
	scene_end("main");

	wb.delete_asset_catalog(asset_catalog);
}