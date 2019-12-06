package net

using import "core:fmt"
import "core:strings"
import "core:reflect"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"
using import "shared:workbench/math"

entity_packet_handlers : map[typeid]^Entity_Packet_Handler;

Entity_Packet_Handler :: struct {
    receive: proc(Entity, Entity_Packet),
}

add_entity_packet_handler :: proc($Type: typeid, receive: proc(Entity, Entity_Packet)) {
    if entity_packet_handlers == nil {
        entity_packet_handlers = make(map[typeid]^Entity_Packet_Handler, 1);
    }
    
    id := typeid_of(Type);
    entity_packet_handlers[id] = new_clone(Entity_Packet_Handler { receive });
}

initialize_entity_handlers :: proc() {
    when SERVER {
        add_entity_packet_handler(Transform_Packet, server_receive_transform);
    } else {
        add_entity_packet_handler(Transform_Packet, client_receive_transform);
    }
}

handle_packet_receive :: proc(t: typeid) -> (^Entity_Packet_Handler, bool) {
    handler, exists := entity_packet_handlers[t];
    
    if !exists {
        logln("Cannot find type ", t, " in entity packet handlers");
        return {}, false;
    }
    
    return handler, true;
}

update_networked_entities :: proc() {
    when SERVER {
    } else {
        for net_id in get_component_storage(Network_Id) {
            transform, exists := get_component(net_id.e, Transform);
            packet := Packet{
                Entity_Packet {
                    net_id.network_id,
                    Transform_Packet {
                        transform.position,
                        transform.rotation,
                        transform.scale
                    }
                }
            };
            send_packet(&packet);
        }
    }
}

client_entity_receive :: proc(packet: Packet, client_id: int) {
    ep := packet.data.(Entity_Packet);
    target_entity : Entity;
    
    handler, exists := handle_packet_receive(reflect.union_variant_typeid(ep.data));
    if !exists do return;
    
    // TODO optimize this
    // Get the entity from the network id
    for net_id in get_component_storage(Network_Id) {
        if net_id.network_id == ep.network_id {
            target_entity = net_id.e;
        }
    }
    
    handler.receive(target_entity, ep);
}

when SERVER {
    server_entity_receive :: proc(packet: Packet, client_id: int) {
        ep := packet.data.(Entity_Packet);
        target_entity : Entity;
        
        handler, exists := handle_packet_receive(reflect.union_variant_typeid(ep.data));
        if !exists do return;
        
        // TODO optimize this
        // Get the entity from the network id
        for net_id in get_component_storage(Network_Id) {
            if net_id.network_id == ep.network_id {
                target_entity = net_id.e;
            }
        }
        
        handler.receive(target_entity, ep);
    }
}

// components
Network_Id :: struct {
    using base: Component_Base,
    network_id: int,
    controlling_client: int,
}

// packets
Entity_Packet :: struct {
    network_id: int,
    data: union {
        Transform_Packet
    }
}

// Transform packet
Transform_Packet :: struct {
    position: Vec3,
    rotation: Quat,
    scale: Vec3,
}

server_receive_transform :: proc(entity: Entity, packet: Entity_Packet) {
    tp := packet.data.(Transform_Packet);
    
    // TODO handle interpolating between client and server transforms
    trans_comp, ok := get_component(entity, Transform);
    trans_comp.position = tp.position;
    trans_comp.rotation = tp.rotation;
    trans_comp.scale = tp.scale;
}

client_receive_transform :: proc(entity: Entity, packet: Entity_Packet) {
    tp := packet.data.(Transform_Packet);
    
    // TODO handle interpolating between client and server transforms
    trans_comp, ok := get_component(entity, Transform);
    trans_comp.position = tp.position;
    trans_comp.rotation = tp.rotation;
    trans_comp.scale = tp.scale;
}