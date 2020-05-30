package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/platform"
import "shared:wb/ecs"

import "configs"
import "shared"
import "editor"
import "net"
import "game"
import "physics"

logln :: logging.logln;

main_init :: proc() {
	//
	configs.init_key_config();
    configs.init_config();
    
    //
    net.network_init();
    net.initialize_entity_handlers();
    
    using ecs;
    add_component_type(Transform, nil, nil);
    
    // physics components
    add_component_type(physics.Collider, physics.update_collider, physics.render_collider, physics.init_collider);
    
    // network components
    add_component_type(net.Network_Id, nil, nil);
    
    // game components
    // Rendering
    add_component_type(game.Animator, game.update_animator, nil, game.init_animator, nil, game.editor_render_animator);
    add_component_type(game.Particle_Emitter, game.update_emitter, nil, game.init_emitter);
    add_component_type(game.Model_Renderer, nil, game.render_model_renderer, game.init_model_renderer);
    add_component_type(game.Terrain, nil, game.render_terrain, game.init_terrain, nil, game.editor_render_terrain);

    // Support
    add_component_type(game.Stats, nil, nil, game.init_stat_component);
    add_component_type(game.Health, nil, nil, game.init_health);

    // NPC
    add_component_type(game.Enemy_Spawner, game.update_enemy_spawner, nil, game.init_enemy_spawner);
    add_component_type(game.Enemy, game.update_enemy, nil, game.init_enemy);

    // Last
    add_component_type(shared.Player_Entity, game.player_update, nil, game.player_init);
    
    //
    game.game_init();
    editor.init();
    
    wb.post_render_proc = on_post_render;
}

main_update :: proc(dt: f32) {
    when !#config(HEADLESS, false) {
        if platform.get_input_down(platform.Input.Escape) do wb.exit();
    }
    
    //
    net.network_update();
    
    //
    game.game_update(dt);
    
    //
    editor.update(dt);
}

main_render :: proc(dt: f32) {
    //
    game.game_render();
}

on_post_render :: proc() {
    game.render_emitters();
    editor.render();
}

main_end :: proc() {
    //
	configs.key_config_save();
    configs.config_save();
    
    //
    net.network_shutdown();
    
    //
	game.game_end();
}

main :: proc() {
    name := "Odinscape";
    when #config(HEADLESS, false) {
        name = fmt.tprint(name, "-server");
    } 
    wb.make_simple_window(1920, 1080, 120,
                          wb.Workspace{name, main_init, main_update, main_render, main_end});
}
