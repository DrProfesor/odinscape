package net

using import "core:fmt"
import enet "shared:odin-enet"
import "core:mem"

using import     "shared:workbench/basic"
using import     "shared:workbench/logging"

IS_CLIENT :: false;

address: enet.Address;
peer: ^enet.Peer;
event: enet.Event;

init :: proc() {
    enet.initialize();
    
    if IS_CLIENT do client_init();
    else do server_init();
}

update :: proc() {
    if IS_CLIENT do client_update();
    else do server_update();
}

shutdown :: proc() {
    enet.deinitialize();
    
    if IS_CLIENT do client_shutdown();
    else do server_shutdown();
}

// client
client: ^enet.Host;

client_init :: proc() {
    client = enet.host_create(nil, 1, 2, 0, 0);
    if client == nil {
        logln("Failed to create socket!");
        return;
    }
    
    host_name := "ec2-34-220-114-38.us-west-2.compute.amazonaws.com\x00";
    enet.address_set_host_ip(&address, & host_name[0]);
    address.port = 27010;
    
    logln("Set Host IP");
    
    peer = enet.host_connect(client, &address, 0, 0);
    if peer == nil {
        logln("Failed to connect to peer!");
        return;
    }
}

client_update :: proc() {
    data := []u32 {1,2,3};
    packet := enet.packet_create(&data[0], size_of(u32) * 3, enet.Packet_Flag.Reliable);
    enet.peer_send(peer, 0, packet);
    enet.host_flush(client);
    
    for enet.host_service(client, &event, 1000) > 0 {
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

// server
server: ^enet.Host;

server_init :: proc() {
    address.host = enet.HOST_ANY;
    address.port = 27010;
    
    server = enet.host_create(&address, 32, 4, 0, 0);
    if server == nil {
        logln("Couldn't create socket!");
        return;
    }
}

server_update :: proc() {
    for enet.host_service(server, &event, 1000) > 0 {
        switch event.event_type {
            case enet.Event_Type.Connect: {
            }
            case enet.Event_Type.Receive: {
                data := event.packet.data;
                length := event.packet.data_len;
                slice: []u8 = mem.slice_ptr(data, int(length));
                
                logln("Received ", slice, "size", length);
            }
            case enet.Event_Type.Disconnect: {
            }
        }
    }
}

server_shutdown :: proc() {
    enet.host_destroy(server);
}