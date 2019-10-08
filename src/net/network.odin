package net

using import "core:fmt"
using import "core:math"
import "core:mem"

import enet "shared:odin-enet"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"

SERVER :: false;

address: enet.Address;
peer: ^enet.Peer;
event: enet.Event;

init :: proc() {
    enet.initialize();
    
    when SERVER {
        server_init();
    } else {
        client_init();
    }
}

update :: proc() {
    when SERVER {
        server_update();
    } else {
        client_update();
    }
}

shutdown :: proc() {
    enet.deinitialize();
    
    when SERVER {
        server_shutdown();
    } else {
        client_shutdown();
    }
}

// client
client: ^enet.Host;

client_init :: proc() {
    client = enet.host_create(nil, 1, 2, 0, 0);
    if client == nil {
        logln("Failed to create socket!");
        return;
    }
    
    host_name := "127.0.0.1\x00";
    enet.address_set_host(&address, & host_name[0]);
    address.port = 27010;
    
    logln("Set Host IP");
    
    peer = enet.host_connect(client, &address, 0, 0);
    if peer == nil {
        logln("Failed to connect to peer!");
        return;
    }
}

client_update :: proc() {
    transform, ok := get_component(Entity(1), Transform);
    p := Packet{
        1,
        Entity_Packet {
            Entity(1),
            Transform_Packet {
                transform.position,
                transform.rotation,
                transform.scale,
            }
        }
    };
    
    packet := enet.packet_create(&p, size_of(Packet), enet.Packet_Flag.Reliable);
    enet.peer_send(peer, 0, packet);
    enet.host_flush(client);
    
    for enet.host_service(client, &event, 1) > 0 {
        switch event.event_type {
            case enet.Event_Type.Connect: {
            }
            case enet.Event_Type.Receive: {
            }
            case enet.Event_Type.Disconnect: {
            }
        }
    }
}

client_shutdown :: proc() {
    enet.host_destroy(client);
    enet.peer_reset(peer);
}

Packet :: struct {
    type_code: u8,
    
    data: union {
        Entity_Packet
    }
}

Entity_Packet :: struct {
    id: Entity,
    
    data: union {
        Transform_Packet
    }
}

Transform_Packet :: struct {
    position: Vec3,
	rotation: Quat,
	scale: Vec3,
}

when SERVER {
    // server
    server: ^enet.Host;
    
    server_init :: proc() {
        address.host = enet.HOST_ANY;
        address.port = 27010;
        
        server = enet.host_create(&address, 32, 4, 0, 0);
        if server == nil {
            logln("Couldn't create server host!");
            return;
        }
        
        logln("Created server host");
    }
    
    server_update :: proc() {
        for enet.host_service(server, &event, 0) > 0 {
            switch event.event_type {
                case enet.Event_Type.Connect: {
                }
                case enet.Event_Type.Receive: {
                    data := event.packet.data;
                    packet := transmute(^Packet) data;
                    
                    switch packet.type_code {
                        case 0: { // invalid packet
                            logln("Received invalid packet from client");
                            return;
                        }
                        case 1: { 
                            packet_data := packet.data.(Entity_Packet);
                            net_transform := packet_data.data.(Transform_Packet);
                            
                            transform, ok := get_component(packet_data.id, Transform);
                            transform.position = net_transform.position;
                            transform.rotation = net_transform.rotation;
                            transform.scale = net_transform.scale;
                        }
                    }
                }
                case enet.Event_Type.Disconnect: {
                }
            }
        }
    }
    
    server_shutdown :: proc() {
        enet.host_destroy(server);
    }
}