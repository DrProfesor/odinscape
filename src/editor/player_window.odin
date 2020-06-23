package editor

import "core:fmt"
import "core:runtime"
import "core:strings"
import "core:mem"

import    "shared:wb/types"
import    "shared:wb/basic"
import    "shared:wb/logging"
import "shared:wb/ecs"

import "shared:wb/external/imgui"

import "../configs"
import "../game"

update_player_window :: proc(userdata: rawptr) {

    // if imgui.begin("Player") {

    //     // model id
    //     // todo(jake) genericify this
    //     @static model_id_buffer: [1024]u8;
    //     fmt.bprint(model_id_buffer[:], configs.player_config.model_id);

    //     configs.player_config.model_id = input_text("Model", model_id_buffer[:]);

    //     if imgui.begin_drag_drop_target() {
    //         payload := imgui.accept_drag_drop_payload("resource", imgui.Drag_Drop_Flags(0));
    //         if payload != nil {
    //             fname, ok := basic.get_file_name(current_drag_drop_payload);
    //             configs.player_config.model_id = fname;
    //             model_id_buffer = {};
    //             current_drag_drop_payload = "";

    //             if game.local_player != 0 {
    //                 m, exists := ecs.get_component(game.local_player, game.Model_Renderer);
    //                 m.texture_id = fname;
    //             }
    //         }
    //         imgui.end_drag_drop_target();
    //     }

    //     // texture id
    //     @static texture_id_buffer: [1024]u8;
    //     fmt.bprint(texture_id_buffer[:], configs.player_config.texture_id);

    //     configs.player_config.texture_id = input_text("Texture", texture_id_buffer[:]);

    //     if imgui.begin_drag_drop_target() {
    //         payload := imgui.accept_drag_drop_payload("resource", imgui.Drag_Drop_Flags(0));
    //         if payload != nil {
    //             fname, ok := basic.get_file_name(current_drag_drop_payload);
    //             configs.player_config.texture_id = fname;
    //             texture_id_buffer = {};
    //             current_drag_drop_payload = "";

    //             if game.local_player != 0 {
    //                 m, exists := ecs.get_component(game.local_player, game.Model_Renderer);
    //                 m.texture_id = fname;
    //             }
    //         }
    //         imgui.end_drag_drop_target();
    //     }

    // } imgui.end();
}

input_text :: proc(label: string, buf: []byte) -> string {
    imgui.input_text(label, buf);
    buf[len(buf)-1] = 0;
    text := cast(string)cast(cstring)&buf[0];
    return text;
}