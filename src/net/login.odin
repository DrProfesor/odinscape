package net

import "shared:wb/external/imgui"

is_logged_in := false;

@static username_buf: [1024]u8;

handle_login_response :: proc(packet: Packet, client_id: int) {
	response := packet.data.(Login_Response_Packet);

	if response.success {
		is_logged_in = true;
	} else {
		panic("Failed to login");
	}
}

update_login :: proc() {
	if is_logged_in do return;

	if imgui.begin("Login") {
		imgui.input_text("", username_buf[:]);
	    username_buf[len(username_buf)-1] = 0;
	    user_name := cast(string)cast(cstring)&username_buf[0];

	    if imgui.button("Login") {
	    	login_packet := Packet{
	        	Login_Packet {
		            client_id,
		            username_buf,
		        }
		    };

		    send_packet(&login_packet);
	    }

		imgui.end();
	}
}