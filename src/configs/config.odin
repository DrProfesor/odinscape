package configs

import "core:os"
import "core:mem"
using import "core:fmt"
using import "shared:workbench/math"

import wb   "shared:workbench"
import platform "shared:workbench/platform"
import wbml "shared:workbench/wbml"

CONFIG_PATH :: "resources/data/";

editor_config : Editor_Config;
player_config : Player_Config;

init_config :: proc() {
    player_c, p_ok := os.read_entire_file(tprint(CONFIG_PATH, "player.wbml"));
    player_config = default_player_config();
    if p_ok {
        wbml.deserialize(player_c, &player_config);
    }
    
    editor_c, e_ok := os.read_entire_file(tprint(CONFIG_PATH, "editor.wbml"));
    editor_config = default_editor_config();
    if e_ok {
        wbml.deserialize(editor_c, &editor_config);
    }
    
    config_save();
}

config_save :: proc() {
    p_ser := wbml.serialize(&player_config);
    defer delete(p_ser);
    os.write_entire_file(tprint(CONFIG_PATH, "player.wbml"), cast([]u8)p_ser);
    
    e_ser := wbml.serialize(&editor_config);
    defer delete(e_ser);
    os.write_entire_file(tprint(CONFIG_PATH, "editor.wbml"), cast([]u8)e_ser);
}

default_player_config :: proc() -> Player_Config {
    return Player_Config {
        "mrknight",
        "blue_knight",
    };
}

default_editor_config :: proc() -> Editor_Config {
    return Editor_Config {
        true,
        
        Vec3{}, Quat{},
    };
}


Player_Config :: struct {
    model_id : string,
    texture_id : string,
}

Editor_Config :: struct {
    enabled : bool,
    
    camera_position: Vec3,
    camera_rotation: Quat,
}

