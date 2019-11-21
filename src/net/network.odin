package net

using import "core:fmt"
import reflect "core:reflect"
import "core:mem"
import "core:strings"

import enet "shared:odin-enet"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/wbml"
using import "shared:workbench/ecs"

using import "../shared"

address: enet.Address;
peer: ^enet.Peer;
event: enet.Event;
host: ^enet.Host;

packet_handlers : map[typeid]^Packet_Handler;

Packet_Handler :: struct {
    receive: proc(Packet, int),
}

add_packet_handler :: proc($Type: typeid, receive: proc(Packet, int)) {
    if packet_handlers == nil {
        packet_handlers = make(map[typeid]^Packet_Handler, 1);
    }
    
    id := typeid_of(Type);
    packet_handlers[id] = new_clone(Packet_Handler{ receive });
}

network_init :: proc() {
    enet.initialize();
    
    when SERVER {
        add_packet_handler(Entity_Packet, server_entity_receive);
        add_packet_handler(Login_Packet, handle_login);
        
        server_init();
    } else {
        add_packet_handler(Connection_Packet, handle_connect);
        add_packet_handler(Net_Create_Entity, handle_create_entity);
        add_packet_handler(Net_Add_Component, handle_add_component);
        
        add_packet_handler(Entity_Packet, client_entity_receive);
        
        client_init();
    }
}

network_update :: proc() {
    when SERVER {
        server_update();
    } else {
        client_update();
    }
}

network_shutdown :: proc() {
    enet.deinitialize();
    
    when SERVER {
        server_shutdown();
    } else {
        client_shutdown();
    }
}

// client
client_id : int;

client_init :: proc() {
    
    host = enet.host_create(nil, 1, 2, 0, 0);
    if host == nil {
        logln("Failed to create socket!");
        return;
    }
    
    host_name := "127.0.0.1\x00";
    enet.address_set_host(&address, &host_name[0]);
    address.port = 27010;
    
    logln("Set Host IP");
    
    peer = enet.host_connect(host, &address, 0, 0);
    if peer == nil {
        logln("Failed to connect to peer!");
        return;
    }
}

client_update :: proc() {
    for enet.host_service(host, &event, 1) > 0 {
        switch event.event_type {
            case enet.Event_Type.Connect: {
            }
            case enet.Event_Type.Receive: {
                packet_string := strings.string_from_ptr(cast(^byte)event.packet.data, int(event.packet.data_len));
                packet := wbml.deserialize(Packet, cast([]u8)packet_string);
                
                packet_typeid := reflect.union_variant_typeid(packet.data);
                handler := packet_handlers[packet_typeid];
                handler.receive(packet, client_id);
            }
            case enet.Event_Type.Disconnect: {
            }
        }
    }
}

client_shutdown :: proc() {
    enet.host_destroy(host);
    enet.peer_reset(peer);
}

send_packet :: proc(built_packet: ^Packet) {
    serialized_packet := wbml.serialize(built_packet);
    raw_string := mem.raw_data(serialized_packet);
    e_packet := enet.packet_create(raw_string, uint(len(serialized_packet)), enet.Packet_Flag.Reliable);
    enet.peer_send(peer, 0, e_packet);
    enet.host_flush(host);
}

// client handlers
handle_connect :: proc(packet: Packet, cid: int) {
    con_packet := packet.data.(Connection_Packet);
    
    client_id = con_packet.client_id;
    
    login_packet := Packet{
        Login_Packet {
            con_packet.client_id,
        }
    };
    
    send_packet(&login_packet);
}

handle_create_entity :: proc(packet: Packet, client_id: int) {
    ce := packet.data.(Net_Create_Entity);
    
    new_entity := make_entity();
    net_id := add_component(new_entity, Network_Id);
    net_id.network_id = ce.network_id;
    net_id.controlling_client = ce.controlling_client;
}

handle_add_component :: proc(packet: Packet, client_id: int) {
    ac := packet.data.(Net_Add_Component);
    
    for net_id in get_component_storage(Network_Id) {
        if net_id.network_id == ac.network_id {
            component_type := ecs.get_component_ti_from_name(ac.component_type);
            add_component_by_typeid(net_id.base.e, component_type.id);
            return;
        }
    }
    
    logln("Failed to find networked entity locally", ac.network_id);
}

// Server side
when SERVER {
    
    connected_clients := make([dynamic]^Client, 0, 10);
    last_client_id : int = 0;
    
    server_init :: proc() {
        address.host = enet.HOST_ANY;
        address.port = 27010;
        
        host= enet.host_create(&address, 32, 4, 0, 0);
        if host == nil {
            logln("Couldn't create server host!");
            return;
        }
        
        logln("Created server host");
    }
    
    server_update :: proc() {
        for enet.host_service(host, &event, 0) > 0 {
            switch event.event_type {
                case enet.Event_Type.Connect: {
                    
                    last_client_id += 1;
                    client := Client{
                        last_client_id,
                        event.peer.address,
                        event.peer,
                    };
                    
                    
                    append(&connected_clients, new_clone(client));
                    
                    con_packet := Packet{
                        Connection_Packet{
                            last_client_id
                        }
                    };
                    
                    dispatch_packet_to_peer(event.peer, &con_packet);
                }
                case enet.Event_Type.Receive: {
                    packet_string := strings.string_from_ptr(cast(^byte)event.packet.data, int(event.packet.data_len));
                    packet := wbml.deserialize(Packet, packet_string);
                    
                    client_id := 0;
                    for client in connected_clients {
                        if client.peer == event.peer {
                            client_id = client.client_id;
                        }
                    }
                    
                    packet_typeid := reflect.union_variant_typeid(packet.data);
                    handler := packet_handlers[packet_typeid];
                    handler.receive(packet, client_id);
                }
                
                case enet.Event_Type.Disconnect: {
                }
            }
        }
    }
    
    server_shutdown :: proc() {
        enet.host_destroy(host);
    }
    
    // server utility procedures
    dispatch_packet_to_peer :: proc(peer: ^enet.Peer, packet: ^Packet) {
        serialized_packet := wbml.serialize(packet);
        raw_string := mem.raw_data(serialized_packet);
        e_packet := enet.packet_create(raw_string, uint(len(serialized_packet)), enet.Packet_Flag.Reliable);
        enet.peer_send(peer, 0, e_packet);
        enet.host_flush(host); // TODO move this to update?
    }
    
    broadcast :: proc(packet: ^Packet) {
        for client in connected_clients {
            dispatch_packet_to_peer(client.peer, packet);
        }
    }
    
    last_net_id : int = 0;
    network_entity :: proc(entity: Entity, controlling_client_id: int) {
        last_net_id += 1;
        net_id := add_component(entity, Network_Id);
        net_id.network_id = last_net_id;
        net_id.controlling_client = controlling_client_id;
        
        create_entity := Packet {
            Net_Create_Entity {
                last_net_id,
                controlling_client_id
            }
        };
        broadcast(&create_entity);
    }
    
    network_create_entity :: proc(name := "Entity", client_id: int) -> Entity {
        new_entity := make_entity(name);
        
        network_entity(new_entity, client_id);
        
        return new_entity;
    }
    
    network_add_component :: proc(entity: Entity, $Type: typeid) {
        
        // TODO optimize this could get real slow
        nid := Network_Id{};
        for net_id in get_component_storage(Network_Id) {
            if net_id.e == entity {
                nid = net_id;
            }
        }
        
        assert(nid.network_id != 0);
        
        add_component_by_typeid(entity, typeid_of(Type));
        add_comp := Packet {
            Net_Add_Component {
                nid.network_id,
                tprint(typeid_of(Type)),
            }
        };
        
        broadcast(&add_comp);
    }
    
    // server handlers
    handle_login :: proc(packet: Packet, client_id: int) {
        lp := packet.data.(Login_Packet);
        
        // TODO send player create packet
        new_player := make_entity("Player");
        network_entity(new_player, client_id);
        network_add_component(new_player, Player_Entity);
    }
    
    // server side structs
    Client :: struct {
        client_id: int,
        
        address: enet.Address,
        peer: ^enet.Peer,
    }
}



//
// Packet definitions
//
Packet :: struct {
    data: union {
        // login packets
        Connection_Packet,
        Login_Packet,
        
        //
        Net_Create_Entity,
        Net_Add_Component,
        
        // runtime
        Entity_Packet,
    }
}

Connection_Packet :: struct {
    client_id: int,
}

Login_Packet :: struct {
    client_id: int,
}

Net_Create_Entity :: struct {
    network_id : int,
    controlling_client: int,
}

Net_Add_Component :: struct {
    network_id : int,
    component_type: string,
}
