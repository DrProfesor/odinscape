package main

using import "core:fmt"
using import "core:math"
import "core:mem"
import "core:os"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"
import wb        "shared:workbench"
import platform  "shared:workbench/platform"

using import "configs"
import "editor"
//import "game"

main_init :: proc() {
	//
	init_key_config();
    
    //
    game_init();
    
    //
    editor.init();
}

main_update :: proc(dt: f32) {
    if platform.get_input_down(platform.Input.Escape) do wb.exit();
    
    //
    game_update(dt);
    
    //
    editor.update(dt);
}

main_render :: proc(dt: f32) {
    //
    game_render();
    
    //
    editor.render();
}

main_end :: proc() {
    //
	key_config_save();
    
    //
	game_end();
}

main :: proc() {
    wb.make_simple_window(1920, 1080, 3, 3, 120,
                          wb.Workspace{"Odinscape", main_init, main_update, main_render, main_end});
}

