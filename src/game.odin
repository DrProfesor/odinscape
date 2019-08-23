package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"
import wb        "shared:workbench"
import platform  "shared:workbench/platform"
import coll      "shared:workbench/collision"
import wbmath    "shared:workbench/math"
import ai        "shared:workbench/external/assimp"
import imgui     "shared:workbench/external/imgui"
import gpu       "shared:workbench/gpu"

DEVELOPER :: true;

asset_catalog: wb.Asset_Catalog;
main_collision_scene: coll.Collision_Scene;
shader_texture_lit: gpu.Shader_Program;

game_init :: proc() {

	{
		wb.load_asset_folder("resources", &asset_catalog, "material", "txt", "e");
	}

	// shaders
	{
		ok: bool;
		shader_texture_lit, ok = gpu.load_shader_text(SHADER_TEXTURE_LIT_VERT, SHADER_TEXTURE_LIT_FRAG);
		assert(ok);
	}

	// camera
	{
		wb.wb_camera.is_perspective = true;
		wb.wb_camera.size = 70;
		wb.wb_camera.position = Vec3{0, 6.09, 4.82};
		wb.wb_camera.rotation = Quat{-0.500628, 0, 0, 0.865663};
	}

    // entities
	{
		em_add_component_type(Transform, nil, nil);
		em_add_component_type(Model_Renderer, nil, render_model_renderer, init_model_renderer);

		scene_init("main");
	}

	//
	//add_selected_unit(player_input_manager.player_entity);
	//focus_camera_on_guy(player_input_manager.player_entity);

	//
	wb.register_debug_program("Odinscape Debug", debug_window_proc, nil);
}

game_update :: proc(dt: f32) {
	em_update(dt);
}

game_render :: proc() {
    em_render();
}

game_end :: proc() {
	scene_end("main");

	wb.delete_asset_catalog(asset_catalog);
}