package game

import "core:fmt"

import "shared:wb/imgui"

import "../shared"
import "../net"

@static username_buf: [1024]u8;
@static new_character_name_buf: [1024]u8;

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

	    if imgui.button("Doc") {
	    	fmt.bprint(username_buf[:], "Doc");
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

loaded_character := -1;

update_character_select_screen :: proc() {
	if shared.Current_Game_State != .Character_Select do return;
	if loaded_character >= 0 do return;
	
	imgui.set_next_window_pos({0,0});
	imgui.set_next_window_size({shared.WINDOW_SIZE_X,shared.WINDOW_SIZE_Y});
	if imgui.begin("CharacterSelect") {
		for character, i in local_player_save.characters {
			if !character.valid do continue;
			
			if imgui.button(character.character_name) {
				loaded_character = i;
				
				character_select_packet := net.Packet {
					net.Character_Select_Packet { i }
				};
				net.send_packet(&character_select_packet);
			}
		}

		imgui.input_text("", username_buf[:]);
	    username_buf[len(username_buf)-1] = 0;
	    if imgui.button("Create Player") {
	    	// TODO
	    }

		imgui.end();
	}
}