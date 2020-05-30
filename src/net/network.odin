package net

import "core:fmt"
import reflect "core:reflect"
import "core:mem"
import "core:strings"
import "core:time"

import enet "shared:odin-enet"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/wbml"
import "shared:wb/ecs"
import "shared:wb/math"

import "../shared"

logln :: logging.logln;
Entity :: ecs.Entity;

address: enet.Address;
peer: ^enet.Peer;
event: enet.Event;
host: ^enet.Host;

when #config(HEADLESS, false) {
is_client := false;
is_server := true;
} else {
is_client := true;
is_server := false;
}

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

    when #config(HEADLESS, false) {
        // Core
        add_packet_handler(Entity_Packet, server_entity_receive);
        add_packet_handler(Login_Packet, handle_login);
        add_packet_handler(Logout_Packet, handle_logout);
        add_packet_handler(Keep_Alive_Packet, handle_keep_alive);

        // Runtime
        add_packet_handler(Player_Packet, recieve_player_packet);
        add_packet_handler(Replication_Packet, handle_replication);

        server_init();
    } else {
        // Core
        add_packet_handler(Connection_Packet, handle_connect);
        add_packet_handler(Create_Entity_Packet, handle_create_entity);
        add_packet_handler(Net_Add_Component, handle_add_component);

        // Runtime
        add_packet_handler(Entity_Packet, client_entity_receive);
        add_packet_handler(Player_Packet, recieve_player_packet_client);
        add_packet_handler(Replication_Packet, handle_replication);

        client_init();
    }
}

network_update :: proc() {
    when #config(HEADLESS, false) {
        server_update();
    } else {
        client_update();
    }

    update_networked_entities();
}

network_shutdown :: proc() {
    enet.deinitialize();

    when #config(HEADLESS, false) {
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

    host_name := "127.0.0.1\x00"; //"ec2-34-232-169-211.compute-1.amazonaws.com\x00";
    enet.address_set_host(&address, cast(^u8)strings.ptr_from_string(host_name));
    address.port = 27010;

    logln("Set Host IP");

    peer = enet.host_connect(host, &address, 0, 0);
    if peer == nil {
        logln("Failed to connect to peer!");
        return;
    }
}

TIMEOUT : f64 : 5;

client_update :: proc() {
    for enet.host_service(host, &event, 1) > 0 {
        switch event.event_type {
            case .None: { }
            case .Connect: {
                logln("Connected to peer");
            }
            case .Receive: {
                packet_string := strings.string_from_ptr(cast(^byte)event.packet.data, int(event.packet.data_len));
                packet := wbml.deserialize(Packet, transmute([]u8)packet_string);

                packet_typeid := reflect.union_variant_typeid(packet.data);
                handler := packet_handlers[packet_typeid];
                handler.receive(packet, client_id);
            }
            case .Disconnect: {
            }
        }
    }

    @static last_sent_time : f64 = 0;
    now := f64(time.now()._nsec) / f64(time.Second);
    if now - last_sent_time > TIMEOUT {
        keep_alive := Packet { Keep_Alive_Packet { client_id } };
        send_packet(&keep_alive);
        last_sent_time = now;
    }
}

client_shutdown :: proc() {
    logln("Client shutdown");
    logout_packet := Packet { Logout_Packet {
        client_id
    }};
    send_packet(&logout_packet);
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
    ce := packet.data.(Create_Entity_Packet);

    new_entity := ecs.make_entity();
    net_id := ecs.add_component(new_entity, Network_Id);
    net_id.network_id = ce.network_id;
    net_id.controlling_client = ce.controlling_client;

    transform, ok := ecs.get_component(new_entity, ecs.Transform);
    assert(ok);
    transform.position = ce.position;
    transform.rotation = ce.rotation;
    transform.scale = ce.scale;
}

handle_add_component :: proc(packet: Packet, client_id: int) {
    ac := packet.data.(Net_Add_Component);

    @static active_net_id_componenets: [dynamic]Network_Id;
    clear(&active_net_id_componenets);
    ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

    for net_id in active_net_id_componenets {
        if net_id.network_id == ac.network_id {
            component_type := ecs.get_component_ti_from_name(ac.component_type);
            logln("Added network component: ", component_type, net_id.network_id, net_id.e);
            ecs.add_component_by_typeid(net_id.base.e, component_type.id);
            return;
        }
    }

    logln("Failed to find networked entity locally", ac.network_id);
}

// Server side
when #config(HEADLESS, false) {

    connected_clients := make([dynamic]^Client, 0, 10);
    last_packet_recieve := make(map[int]f64, 10);
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
            #partial switch event.event_type {
                case enet.Event_Type.Connect: {

                    last_client_id += 1;
                    client := Client{
                        last_client_id,
                        false,
                        event.peer.address,
                        event.peer,
                    };

                    logln("Peer Connected");
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
                    packet := wbml.deserialize(Packet, transmute([]u8)packet_string);

                    client_id := 0;
                    for client in connected_clients {
                        if client.peer == event.peer {
                            client_id = client.client_id;
                        }
                    }

                    if client_id == 0 do continue;

                    now := f64(time.now()._nsec) / f64(time.Second);
                    last_packet_recieve[client_id] = now;

                    packet_typeid := reflect.union_variant_typeid(packet.data);
                    handler := packet_handlers[packet_typeid];
                    handler.receive(packet, client_id);
                }

                case enet.Event_Type.Disconnect: {
                    logln("Removing peer");
                    client_idx := -1;
                    for client, i in connected_clients {
                        if client.peer == event.peer{
                            client_idx = i;
                        }
                    }

                    assert(client_idx >= 0);
                    unordered_remove(&connected_clients, client_idx);
                }
            }
        }

        // timeout clients
        {
            now := f64(time.now()._nsec) / f64(time.Second);
            for cid, t in last_packet_recieve {
                if now - t >= TIMEOUT * 2 && t > 0 {
                    client: ^Client = nil;
                    idx := -1;
                    for c, i in &connected_clients {
                        if c.client_id == cid {
                            client = c;
                            idx = i;
                        }
                    }

                    logln("Client timeout");
                    for net_id in ecs.get_component_storage(Network_Id) {
                        if net_id.controlling_client != cid do continue;
                        ecs.destroy_entity_immediate(net_id.e);
                    }
                    
                    unordered_remove(&connected_clients, idx);
                    last_packet_recieve[cid] = -1;
                    logln("Client disconnected");
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

    broadcast :: proc(packet: ^Packet, ignore: int = -1) {
        for client in connected_clients {
            if client.client_id == ignore do continue;
            if !client.ready_to_receive do continue;
            dispatch_packet_to_peer(client.peer, packet);
        }
    }

    last_net_id : int = 0;
    network_entity :: proc(entity: Entity, controlling_client_id: int) {
        last_net_id += 1;
        net_id := ecs.add_component(entity, Network_Id);
        net_id.network_id = last_net_id;
        net_id.controlling_client = controlling_client_id;

        transform, ok := ecs.get_component(entity, ecs.Transform);
        assert(ok);

        create_entity := Packet {
            Create_Entity_Packet {
                last_net_id,
                controlling_client_id,

                transform.position,
                transform.rotation,
                transform.scale,
            }
        };
        broadcast(&create_entity);

        for k, v in ecs.component_types {
            if k == typeid_of(ecs.Transform) || k == typeid_of(Network_Id) do continue;
            if ecs.has_component(net_id.e, k) {
                add_comp := Packet {
                    Net_Add_Component {
                        net_id.network_id,
                        fmt.tprint(k),
                    }
                };
                broadcast(&add_comp);
            }
        }
    }

    network_create_entity :: proc(name := "Entity", client_id: int) -> Entity {
        new_entity := ecs.make_entity(name);

        network_entity(new_entity, client_id);

        return new_entity;
    }

    network_add_component :: proc(entity: Entity, $T: typeid) -> ^T {

        // TODO optimize this could get real slow
        nid := Network_Id{};
        for net_id in ecs.get_component_storage(Network_Id) {
            if net_id.e == entity {
                nid = net_id;
            }
        }

        assert(nid.network_id != 0);

        comp := cast(^T) ecs.add_component(entity, T);
        // TODO send componenet data over?
        add_comp := Packet {
            Net_Add_Component {
                nid.network_id,
                fmt.tprint(typeid_of(T)),
            }
        };

        logln("Adding component: ", entity, typeid_of(T));

        broadcast(&add_comp);

        return comp;
    }

    network_destroy_entity :: proc(entity: Entity) {
        nid, ok := ecs.get_component(entity, Network_Id);
        assert(ok, "Entity is not networked");

        ecs.destroy_entity_immediate(entity);

        destroy_packet := Packet {
            Destroy_Entity_Packet {
                nid.network_id,
                nid.controlling_client
            }
        };
        broadcast(&destroy_packet);
    }

    // server handlers
    handle_login :: proc(packet: Packet, client_id: int) {
        lp := packet.data.(Login_Packet);

        client := get_client(client_id);

        // dispatch a bunch of entity create calls for networked entities. 
        // TODO this should be done better maybe?
        // TODO we need a better way to get active components
        @static active_net_id_componenets: [dynamic]Network_Id;
        clear(&active_net_id_componenets);
        ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

        for net_id in active_net_id_componenets {

            transform, ok := ecs.get_component(net_id.e, ecs.Transform);
            assert(ok);

            create_entity := Packet {
                Create_Entity_Packet {
                    net_id.network_id,
                    net_id.controlling_client,
                    
                    transform.position,
                    transform.rotation,
                    transform.scale,
                }
            };
            dispatch_packet_to_peer(client.peer, &create_entity);

            for k, v in ecs.component_types {
                if k == typeid_of(ecs.Transform) || k == typeid_of(Network_Id) do continue;
                if ecs.has_component(net_id.e, k) {
                    add_comp := Packet {
                        Net_Add_Component {
                            net_id.network_id,
                            fmt.tprint(k),
                        }
                    };
                    dispatch_packet_to_peer(client.peer, &add_comp);
                }
            }
        }

        client.ready_to_receive = true;

        // TODO send player create packet
        new_player := ecs.make_entity("Player");
        network_entity(new_player, client_id);
        network_add_component(new_player, shared.Player_Entity);
    }

    handle_keep_alive :: proc(packet: Packet, client_id: int) {  }

    handle_logout :: proc(packet: Packet, client_id: int) {
        lp := packet.data.(Logout_Packet);

        client_idx := -1;
        for c, i in connected_clients {
            if c.client_id == client_id{
                client_idx = i;
            }
        }

        logln("Logging out");

        assert(client_idx >= 0);
        unordered_remove(&connected_clients, client_idx);
    }

    get_client :: proc(client_id: int) -> ^Client {
        for c in &connected_clients {
            if c.client_id == client_id do return c;
        }

        assert(false, fmt.tprint("No client found: ",client_id));
        return {};
    }

    // server side structs
    Client :: struct {
        client_id: int,

        ready_to_receive: bool,

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
        Logout_Packet,
        Keep_Alive_Packet,

        //
        Create_Entity_Packet,
        Net_Add_Component,
        Destroy_Entity_Packet,

        // runtime
        Entity_Packet,
        Player_Packet,
        Replication_Packet,
    }
}

Connection_Packet :: struct {
    client_id: int,
}

Login_Packet :: struct {
    client_id: int,
}

Logout_Packet :: struct {
    client_id: int,   
}

Keep_Alive_Packet :: struct {
    client_id: int,
}

Create_Entity_Packet :: struct {
    network_id : int,
    controlling_client: int,

    position: Vec3,
    rotation: Quat,
    scale: Vec3
}

Destroy_Entity_Packet :: struct {
    network_id : int,
    controlling_client: int,
}

Net_Add_Component :: struct {
    network_id : int,
    component_type: string,
}


Vec3 :: math.Vec3;
Quat :: math.Quat;