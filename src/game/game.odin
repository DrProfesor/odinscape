package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/math"

import wb "shared:wb"
import wb_gpu "shared:wb/gpu"

import "../shared"
import "../configs"
import "../net"
import "../entity"

game_init :: proc() {

	if net.is_client {
		wb.track_asset_folder("resources", true);

		wb.main_camera.is_perspective = true;
		wb.main_camera.size = 70;
		wb.main_camera.position = math.Vec3{0, 6.09, 4.82};
		wb.main_camera.rotation = math.Quat{0,0,0,1};

		wb.init_particles();
		wb.init_terrain(); // we still need terrain collision on the server
	}

	configs.add_config_load_listener(entity.on_config_load);

	init_players();
}

game_update :: proc(dt: f32) {
	
	if net.is_client {
		update_login_screen();
		update_character_select_screen();
	}

	if !net.is_logged_in && !net.is_server {
		// wait until we are connected
		return;
	}

	update_players(dt);

    if wb.debug_window_open do return;

    if net.is_client {
    	update_camera(dt);
    }
}

game_render :: proc() {
	if !net.is_logged_in do return;
	
	wb.set_sun_data(math.degrees_to_quaternion({-60, -60, 0}), {1, 1, 1, 1}, 10);

	render_players();
}

game_end :: proc() {
	
}

logln :: logging.logln;
Vec3 :: math.Vec3;
Vec2 :: math.Vec2;
Mat4 :: math.Mat4;
Quat :: math.Quat;

Entity :: entity.Entity;
Player_Character :: entity.Player_Character;
Spell_Caster :: entity.Spell_Caster;
Spell :: entity.Spell;
Spell_Type :: entity.Spell_Type;
Spell_Config_Data :: entity.Spell_Config_Data;