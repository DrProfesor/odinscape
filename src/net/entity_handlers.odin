package net

import "core:fmt"
import "core:strings"
import "core:reflect"

import "shared:workbench/basic"
import "shared:workbench/logging"
import "shared:workbench/ecs"
import "shared:workbench/math"

entity_packet_handlers : map[typeid]^Entity_Packet_Handler;

Entity_Packet_Handler :: struct {
    receive: proc(ecs.Entity, Entity_Packet),
    initialize: proc(ecs.Entity, Entity_Packet),
}

add_entity_packet_handler :: proc($Type: typeid, receive: proc(ecs.Entity, Entity_Packet)) {
    if entity_packet_handlers == nil {
        entity_packet_handlers = make(map[typeid]^Entity_Packet_Handler, 1);
    }

    id := typeid_of(Type);
    entity_packet_handlers[id] = new_clone(Entity_Packet_Handler { receive });
}

initialize_entity_handlers :: proc() {
    when SERVER {
    } else {
    }
}

handle_packet_receive :: proc(t: typeid) -> (^Entity_Packet_Handler, bool) {
    handler, exists := entity_packet_handlers[t];

    if !exists {
        logging.logln("Cannot find type ", t, " in entity packet handlers");
        return {}, false;
    }

    return handler, true;
}

update_networked_entities :: proc() {
    when SERVER {
    } else {
        for net_id in ecs.get_component_storage(Network_Id) {
        }
    }
}

client_entity_receive :: proc(packet: Packet, client_id: int) {
    ep := packet.data.(Entity_Packet);

    handler, exists := handle_packet_receive(reflect.union_variant_typeid(ep.data));
    if !exists do return;

    // TODO optimize this
    // Get the entity from the network id
    for net_id in ecs.get_component_storage(Network_Id) {
        if net_id.network_id == ep.network_id {
            handler.receive(net_id.e, ep);
            return;
        }
    }

    panic(fmt.tprint("Unabled to find entity: ", ep.network_id));
}

when SERVER {
    server_entity_receive :: proc(packet: Packet, client_id: int) {
        ep := packet.data.(Entity_Packet);
        target_entity : Entity;

        handler, exists := handle_packet_receive(reflect.union_variant_typeid(ep.data));
        if !exists do return;

        // TODO optimize this
        // Get the entity from the network id
        for net_id in ecs.get_component_storage(Network_Id) {
            if net_id.network_id == ep.network_id {
                target_entity = net_id.e;
            }
        }

        handler.receive(target_entity, ep);
    }
}

// components
Network_Id :: struct {
    using base: ecs.Component_Base,
    network_id: int,
    controlling_client: int,
}

// packets
Entity_Packet :: struct {
    network_id: int,
    data: union {
    }
}