package configs

import "core:os"
import "core:mem"
using import "core:fmt"

import wb   "shared:workbench"
import platform "shared:workbench/platform"
import wbml "shared:workbench/wbml"

CONFIG_PATH :: "resources/data/";

player_config : Player_Config;

init_config :: proc() {
    player_c, p_ok := os.read_entire_file(tprint(CONFIG_PATH, "player.wbml"));
    
    player_config = default_player_config();
    if p_ok {
        wbml.deserialize(player_c, &player_config);
    }
    
    config_save();
}

config_save :: proc() {
    p_ser := wbml.serialize(&player_config);
    defer delete(p_ser);
    os.write_entire_file(tprint(CONFIG_PATH, "player.wbml"), cast([]u8)p_ser);
}

default_player_config :: proc() -> Player_Config {
    return Player_Config{
        "mrknight",
        "blue_knight",
    };
}


Player_Config :: struct {
    model_id : string,
    texture_id : string,
}


