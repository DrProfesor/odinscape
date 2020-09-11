package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"
import "configs"
import "shared"
import "editor"
import "net"
import "game"
import "physics"

logln :: logging.logln;

main_init :: proc() {
    
    configs.init();
    net.init();
    game.init();
    editor.init();
    
    // wb.post_render_proc = on_post_render;
    // wb.render_settings.do_shadows = false;
    // wb.render_settings.do_bloom = false;
}

main_update :: proc(dt: f32) -> bool {
    when !#config(HEADLESS, false) {
        // if core.get_input_down(core.Input.Escape) do core.exit();
    }

    net.update(dt);
    game.update(dt);
    editor.update(dt);

    return true;
}

g_main_camera: wb.Camera;
g_screen_render_context: wb.IM_Context;

main_render :: proc() {
    if !net.is_logged_in do return;
    
    @static graphics_memory: []byte;
    if graphics_memory == nil {
        graphics_memory = make([]byte, mem.megabytes(10));

        g_main_camera = wb.create_camera();
        g_main_camera.is_perspective = true;

        g_main_camera.position = {0, 10, -10};
        g_main_camera.orientation = wb.degrees_to_quaternion({-60, 0, 0});
        g_main_camera.size = 45;
    }

    wb.init_im_context(&g_screen_render_context, &g_main_camera, {0, 0, 0});

    render_graph: wb.Render_Graph;
    wb.init_render_graph(&render_graph, graphics_memory);
    defer wb.destroy_render_graph(&render_graph);

    game.render(&render_graph);
    editor.render(&render_graph);

    wb.add_render_graph_node(&render_graph, "screen", nil, 
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.read_resource(render_graph, "game view");
            wb.has_side_effects(render_graph);
        }, 
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            game_view := wb.get_resource(render_graph, "game view", ^wb.Framebuffer);
            wb.im_quad(&g_screen_render_context, .Pixel, {0,0,0}, {shared.WINDOW_SIZE_X, shared.WINDOW_SIZE_Y, 0}, {1,1,1,1}, &(game_view^).texture);
            // wb.im_text(&g_screen_render_context, .Pixel, {15, 15, 0}, {1, 1, 1, 1}, "This is a Video Game", wb.g_fonts["roboto"]);
            wb.draw_im_context(&g_screen_render_context);
        });

    wb.PUSH_CAMERA(&g_main_camera, true);
    wb.execute_render_graph(&render_graph);
}

main_end :: proc() {
    configs.save();
    net.shutdown();
	game.shutdown();
}

main :: proc() {
    name := "Odinscape";
    when #config(HEADLESS, false) {
        name = fmt.tprint(args={name, "-server"}, sep="");
    } 

    wb.init_wb(name, shared.WINDOW_SIZE_X, shared.WINDOW_SIZE_Y);
    main_init();
   
    wb.start_game_loop(1.0 / 60.0, main_update, main_render);
   
    main_end();
}
