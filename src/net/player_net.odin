package net;

import "shared:wb/basic"
import "shared:wb/logging"

import "../shared"
import "../physics"

send_new_player_position :: proc(pos: Vec3, net_id: int) {
	packet := Packet { Player_Packet {
		net_id, false,
		Player_Target_Position_Packet {
			pos
		}
	}};
	send_packet(&packet);
}

recieve_player_packet_client :: proc(packet: Packet, sending_client_id: int) {
	player_packet := packet.data.(Player_Packet);

	switch d in player_packet.data {
		case Player_Target_Position_Packet: {
		}
	}
}

when #config(HEADLESS, false) {
	recieve_player_packet :: proc(p: Packet, sending_client_id: int) {
		packet := p;
		player_packet := packet.data.(Player_Packet);

        override_sender := false;

        // TODO this is where validation will go
		switch d in player_packet.data {
			case Player_Target_Position_Packet: {
			}
		}
	}
}

Player_Packet :: struct {
	network_id: int,
	is_override_packet: bool,
	data: union {
		Player_Target_Position_Packet,
	}
}

Player_Target_Position_Packet :: struct {
    target: Vec3,
}