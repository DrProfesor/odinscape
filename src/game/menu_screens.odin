package game

import "shared:wb/external/imgui"
import "../shared"
import "../net"

// This file will handle all main menu screens
// login
// character select

@static username_buf: [1024]u8;

update_login_screen :: proc() {
	if shared.Current_Game_State != .Login_Screen do return;

	imgui.set_next_window_pos({0,0});
	imgui.set_next_window_size({shared.WINDOW_SIZE_X,shared.WINDOW_SIZE_Y});
	if imgui.begin("Login") {
		imgui.input_text("", username_buf[:]);
	    username_buf[len(username_buf)-1] = 0;
	    
	    if imgui.button("Login") {
	    	login_packet := net.Packet{
	        	net.Login_Packet {
		            net.client_id,
		            username_buf, // TODO password
		        }
		    };

		    net.send_packet(&login_packet);
	    }

		imgui.end();
	}
}

has_loaded_player := false;

update_character_select_screen :: proc() {
	if shared.Current_Game_State != .Character_Select do return;
	
	imgui.set_next_window_pos({0,0});
	imgui.set_next_window_size({shared.WINDOW_SIZE_X,shared.WINDOW_SIZE_Y});
	if imgui.begin("CharacterSelect") {
		if imgui.button("Load Game") {
		}
		imgui.end();
	}
}