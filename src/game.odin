package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"
import wb        "shared:workbench"
import wb_gpu       "shared:workbench/gpu"

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
		em_add_component_type(Transform, nil, nil);
		em_add_component_type(Model_Renderer, nil, render_model_renderer, init_model_renderer);
        em_add_component_type(Collider, update_collider, render_collider, init_collider);
        
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