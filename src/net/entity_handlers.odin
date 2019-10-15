package net

using import "core:fmt"
using import "core:math"
import "core:strings"

using import "shared:workbench/basic"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"

client_entity_receive :: proc(packet: Packet, client_id: int) {
    ep := packet.data.(Entity_Packet);
    
    target_entity : Entity;
    
    // TODO optimize this
    // Get the entity from the network id
    for net_id in get_component_storage(Network_Id) {
        if net_id.network_id == ep.network_id {
            target_entity = net_id.e;
        }
    }
    
    switch entity_packet_kind in ep.data {
        case Transform_Packet: {
            tp := ep.data.(Transform_Packet);
            
            // TODO handle interpolating between client and server transforms
            trans_comp, ok := get_component(target_entity, Transform);
            trans_comp.position = tp.position;
            trans_comp.rotation = tp.rotation;
            trans_comp.scale = tp.scale;
        }
    }
}

when SERVER {
    server_entity_receive :: proc(packet: Packet, client_id: int) {
        
        ep := packet.data.(Entity_Packet);
        
        switch entity_packet_kind in ep.data {
            case Transform_Packet: {
                
            }
        }
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

Transform_Packet :: struct {
    position: Vec3,
    rotation: Quat,
    scale: Vec3,
}