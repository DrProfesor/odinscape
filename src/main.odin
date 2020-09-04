package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/platform"

import "configs"
import "shared"
import "editor"
import "net"
import "game"
import "physics"

logln :: logging.logln;

main_init :: proc() {
	//
    configs.init_config();
    
    //
    net.network_init();
    
    //
    game.game_init();
    editor.init();
    
    wb.post_render_proc = on_post_render;
    wb.render_settings.do_shadows = false;
    wb.render_settings.do_bloom = false;
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
    editor.render();
    game.game_render();
}

on_post_render :: proc() {
    
}

main_end :: proc() {
    //
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
    wb.make_simple_window(shared.WINDOW_SIZE_X, shared.WINDOW_SIZE_Y, 120,
                          wb.Workspace{name, main_init, main_update, main_render, main_end});
}
