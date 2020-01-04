package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

import wb "shared:workbench"
import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/platform"
import "shared:workbench/ecs"

import "configs"
import "shared"
import "editor"
import "net"
import "game"
import "physics"

main_init :: proc() {
	//
	configs.init_key_config();
    configs.init_config();

    //
    net.network_init();
    net.initialize_entity_handlers();

    //
    game.init_render();

    using ecs;
    add_component_type(Transform, nil, nil);

    // physics components
    add_component_type(physics.Collider, physics.update_collider, physics.render_collider, physics.init_collider);

    // shared
    add_component_type(shared.Player_Entity, game.player_update, nil, game.player_init);

    // network components
    add_component_type(net.Network_Id, nil, nil);

    // game components
    add_component_type(game.Particle_Emitter, game.update_emitter, nil, game.init_emitter);
    add_component_type(game.Model_Renderer, nil, game.render_model_renderer, game.init_model_renderer);
    add_component_type(game.Animator, game.update_animator, nil, game.init_animator, nil, game.editor_render_animator);
    add_component_type(game.Stats, nil, nil);
    add_component_type(game.Health, nil, nil, game.init_health);

    game.game_init();


    //
    editor.init();

    wb.post_render_proc = on_post_render;
}

main_update :: proc(dt: f32) {
    if platform.get_input_down(platform.Input.Escape) do wb.exit();

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
    when SERVER do name = fmt.tprint(name, "-server");
    wb.make_simple_window(1920, 1080, 120,
                          wb.Workspace{name, main_init, main_update, main_render, main_end});
}
