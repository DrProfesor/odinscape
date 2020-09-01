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
import "shared:wb/math"

import "../save"
import "../shared"
import "../entity"

logln :: logging.logln;
Entity :: entity.Entity;

address: enet.Address;
peer: ^enet.Peer;
event: enet.Event;
host: ^enet.Host;

is_connected := false;

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
        add_packet_handler(Login_Response_Packet, handle_login_response);

        // Runtime
        // add_packet_handler(Entity_Packet, client_entity_receive);
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

    // host_name := "127.0.0.1\x00";
    host_name := "ec2-34-232-169-211.compute-1.amazonaws.com\x00";
    enet.address_set_host(&address, cast(^u8)strings.ptr_from_string(host_name));
    address.port = 27010;

    logln("Set Host IP");

    peer = enet.host_connect(host, &address, 0, 0);
    if peer == nil {
        logln("Failed to connect to peer!");
        return;
    }
}

on_login_handlers: [dynamic]proc(save.Player_Save);
local_player_save: save.Player_Save;
is_logged_in := false;

handle_login_response :: proc(packet: Packet, client_id: int) {
    response := packet.data.(Login_Response_Packet);

    if response.success {
        shared.Current_Game_State = .Character_Select;
        for handler in on_login_handlers {
            handler(response.player_save);
        }
    } else {
        panic("Failed to login");
    }
}

TIMEOUT : f64 : 5;

client_update :: proc() {    
    for enet.host_service(host, &event, 1) > 0 {
        switch event.event_type {
            case .None: { }
            case .Connect: {
            }
            case .Receive: {
                packet_string := strings.string_from_ptr(cast(^byte)event.packet.data, int(event.packet.data_len));
                packet := wbml.deserialize(Packet, transmute([]u8)packet_string);

                packet_typeid := reflect.union_variant_typeid(packet.data);
                handler := packet_handlers[packet_typeid];
                handler.receive(packet, client_id);
            }
            case .Disconnect: {
                is_connected = false;
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
    is_connected = true;

    shared.Current_Game_State = .Login_Screen;
}

handle_create_entity :: proc(packet: Packet, client_id: int) {
    
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
                    client := Client {
                        last_client_id,
                        "",
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
                    // destroy player
                    
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
    }

    network_create_entity :: proc(name := "Entity", client_id: int) -> int {
        return 0;
    }

    network_destroy_entity :: proc(entity: Entity) {
        
    }

    // server handlers
    handle_login :: proc(packet: Packet, client_id: int) {
        lp := packet.data.(Login_Packet);
        client := get_client(client_id);

        client.username = cast(string)cast(cstring)&lp.username[0];

        player_save := save.load_player_save(client.username);

        // TODO authenticate
        response_packet := Packet {
            Login_Response_Packet {
                true,
                player_save
            }
        };
        dispatch_packet_to_peer(client.peer, &response_packet);

        client.ready_to_receive = true;
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

        username: string,

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
        Login_Response_Packet,
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

    username: [1024]u8,
}

Login_Response_Packet :: struct {
    success: bool,

    player_save: save.Player_Save,
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