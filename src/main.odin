package main

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"

import "entity"
import "configs"
import "shared"
import "editor"
import "net"
import "game"
import "physics"

logln :: logging.logln;

main_init :: proc() {
    configs.init();
    entity.init();
    net.init();
    game.init();
    editor.init();
}

main_update :: proc(dt: f32) -> bool {
    when !#config(HEADLESS, false) {
        // if core.get_input_down(core.Input.Escape) do core.exit();
    }

    // maybe not in editor?
    // we would have to allow for offline play
    net.update(dt);
    if !wb.developer_menu_open do game.update(dt);
    if  wb.developer_menu_open do editor.update(dt);

    return true;
}

g_main_camera: wb.Camera;
g_screen_context: wb.IM_Context;
g_world_context: wb.IM_Context;
g_editor_context: wb.IM_Context;

main_render :: proc() {
    if !net.is_logged_in do return;
    
    @static graphics_memory: []byte;
    if graphics_memory == nil {
        graphics_memory = make([]byte, mem.megabytes(10));

        wb.init_camera(&g_main_camera);
        g_main_camera.is_perspective = true;

        g_main_camera.position = {0, 10, -10};
        g_main_camera.orientation = wb.degrees_to_quaternion({-60, 0, 0});
        g_main_camera.size = 45;
    }

    wb.init_im_context(&g_screen_context);
    wb.init_im_context(&g_world_context);
    wb.init_im_context(&g_editor_context);

    render_graph: wb.Render_Graph;
    wb.init_render_graph(&render_graph, graphics_memory);
    defer wb.destroy_render_graph(&render_graph);

    render_context: shared.Render_Graph_Context;
    if wb.developer_menu_open {
        render_context.target_camera = &editor.g_editor_camera;
    } else {
        render_context.target_camera = &game.g_game_camera;
    }

    render_context.screen_im_context = &g_screen_context;
    render_context.world_im_context = &g_world_context;
    render_context.editor_im_context = &g_editor_context;

    game.render(&render_graph, &render_context);
    if wb.developer_menu_open do editor.render(&render_graph, &render_context);

    wb.add_render_graph_node(&render_graph, "screen", &render_context, 
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.read_resource(render_graph, "game view color");
            wb.has_side_effects(render_graph);
        }, 
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            render_context := cast(^shared.Render_Graph_Context)userdata;

            pass: wb.Render_Pass;
            pass.camera = &g_main_camera;
            wb.BEGIN_RENDER_PASS(&pass);

            game_view := wb.get_resource(render_graph, "game view color", wb.Texture);
            wb.im_quad(&g_screen_context, .Pixel, {0,0,0}, {shared.WINDOW_SIZE_X, shared.WINDOW_SIZE_Y, 0}, {1,1,1,1}, game_view);

            wb.draw_im_context(&g_world_context, &g_main_camera);
            wb.draw_im_context(&g_screen_context, &g_main_camera);
        });

    wb.execute_render_graph(&render_graph);
}

main_end :: proc() {
    net.shutdown();
	game.shutdown();
    editor.shutdown();
    configs.save();
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
