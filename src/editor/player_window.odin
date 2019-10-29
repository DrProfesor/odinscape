package editor

using import "core:fmt"
using import "core:runtime"
using import "core:strings"
import "core:mem"

using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"
using import "shared:workbench/ecs"

import "shared:workbench/external/imgui"

import "../configs"
import "../game"

update_player_window :: proc(dt: f32) {
    
    if imgui.begin("Player") {
        
        // model id
        // todo(jake) genericify this
        @static model_id_buffer: [1024]u8;
        bprint(model_id_buffer[:], configs.player_config.model_id);
        
        configs.player_config.model_id = input_text("Model", model_id_buffer[:]);
        
        if imgui.begin_drag_drop_target() {
            payload := imgui.accept_drag_drop_payload("resource", imgui.Drag_Drop_Flags(0));
            if payload != nil {
                fname, ok := get_file_name(current_drag_drop_payload);
                configs.player_config.model_id = fname;
                model_id_buffer = {};
                current_drag_drop_payload = "";
                
                if game.local_player != 0 {
                    m, exists := get_component(game.local_player, game.Model_Renderer);
                    m.texture_id = fname;
                }
            }
            imgui.end_drag_drop_target();
        }
        
        // texture id
        @static texture_id_buffer: [1024]u8;
        bprint(texture_id_buffer[:], configs.player_config.texture_id);
        
        configs.player_config.texture_id = input_text("Texture", texture_id_buffer[:]);
        
        if imgui.begin_drag_drop_target() {
            payload := imgui.accept_drag_drop_payload("resource", imgui.Drag_Drop_Flags(0));
            if payload != nil {
                fname, ok := get_file_name(current_drag_drop_payload);
                configs.player_config.texture_id = fname;
                texture_id_buffer = {};
                current_drag_drop_payload = "";
                
                if game.local_player != 0 {
                    m, exists := get_component(game.local_player, game.Model_Renderer);
                    m.texture_id = fname;
                }
            }
            imgui.end_drag_drop_target();
        }
        
    } imgui.end();
}

input_text :: proc(label: string, buf: []byte) -> string {
    imgui.input_text(label, buf);
    buf[len(buf)-1] = 0;
    text := cast(string)cast(cstring)&buf[0];
    return text;
}