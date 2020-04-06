package net;

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/ecs"

import "../shared"
import "../physics"

send_new_player_position :: proc(pos: Vec3, net_id: int) {
	packet := Packet { Player_Packet {
		net_id,
		false,
		Player_Target_Position_Packet {
			pos
		}
	}};
	send_packet(&packet);
}

recieve_player_packet_client :: proc(packet: Packet, sending_client_id: int) {
	player_packet := packet.data.(Player_Packet);
	logln("Recieved Player Packet:", player_packet);

	network_id: Network_Id;
	for net_id in ecs.get_component_storage(Network_Id) {
		if net_id.network_id == player_packet.network_id {
			network_id = net_id;
		}
    }

	switch d in player_packet.data {
		case Player_Target_Position_Packet: {
			player_comp, ok := ecs.get_component(network_id.e, shared.Player_Entity);
			transform, _ := ecs.get_component(player_comp.e, ecs.Transform);
			assert(ok);
			player_comp.target_position = d.target;
			player_comp.player_path = physics.smooth_a_star(transform.position, player_comp.target_position, 0.25);
            player_comp.path_idx = 0;
		}
	}
}

when SERVER {
	recieve_player_packet :: proc(p: Packet, sending_client_id: int) {
		packet := p;
		player_packet := packet.data.(Player_Packet);
		logln("Recieved Player Packet:", player_packet);

		network_id: Network_Id;
		for net_id in ecs.get_component_storage(Network_Id) {
			if net_id.network_id == player_packet.network_id {
				network_id = net_id;
			}
        }

        override_sender := false;

        // TODO this is where validation will go
		switch d in player_packet.data {
			case Player_Target_Position_Packet: {
				player_comp, ok := ecs.get_component(network_id.e, shared.Player_Entity);
				transform, _ := ecs.get_component(player_comp.e, ecs.Transform);
				assert(ok);
				player_comp.target_position = d.target;
				player_comp.player_path = physics.smooth_a_star(transform.position, player_comp.target_position, 0.25);
            	player_comp.path_idx = 0;
			}
		}

		if override_sender {
			broadcast(&packet);
		} else {
			broadcast(&packet, sending_client_id);
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