package net

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:reflect"
import "core:mem"
import rt "core:runtime"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/ecs"
import "shared:wb/math"
import "shared:wb/wbml"

entity_packet_handlers : map[typeid]^Entity_Packet_Handler;

Entity_Packet_Handler :: struct {
    receive: proc(ecs.Entity, Entity_Packet),
}

add_entity_packet_handler :: proc($Type: typeid, receive: proc(ecs.Entity, Entity_Packet)) {
    if entity_packet_handlers == nil {
        entity_packet_handlers = make(map[typeid]^Entity_Packet_Handler, 1);
    }

    id := typeid_of(Type);
    entity_packet_handlers[id] = new_clone(Entity_Packet_Handler { receive });
}

initialize_entity_handlers :: proc() {
    when #config(HEADLESS, false) {

    } else {
        add_entity_packet_handler(Transform_Packet, handle_transform_packet);
    }
}

get_entity_packet_handler :: proc(t: typeid) -> (^Entity_Packet_Handler, bool) {
    handler, exists := entity_packet_handlers[t];

    if !exists {
        logging.logln("Cannot find type ", t, " in entity packet handlers");
        return {}, false;
    }

    return handler, true;
}

handle_transform_packet :: proc(entity: ecs.Entity, packet: Entity_Packet) {
    target_transform, exists := ecs.get_component(entity, ecs.Transform);
    assert(exists);

    transform_data := packet.data.(Transform_Packet);
    target_transform.position = transform_data.position;
    target_transform.rotation = transform_data.rotation;
    target_transform.scale = transform_data.scale;
}

handle_replication :: proc(packet: Packet, client_id: int) {
    replication_data := packet.data.(Replication_Packet);
    for field in replication_data.modified_fields {
        parts := strings.split(field, ";");
        key_parts := strings.split(parts[0], ":");
        target_network_id, _ := strconv.parse_int(key_parts[0]);

        @static active_net_id_componenets: [dynamic]Network_Id;
        clear(&active_net_id_componenets);
        ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

        for net_id in active_net_id_componenets {
            if net_id.network_id != target_network_id do continue;

            when #config(HEADLESS, false) {
                if net_id.controlling_client != client_id do continue;
            }
            
            for k, v in ecs.component_types {
                if fmt.tprint(k) != key_parts[1] do continue;

                ptr, ok := ecs.get_component_ptr(net_id.e, k);
                assert(ok);

                struct_type_info: rt.Type_Info_Struct;
                #partial switch kind in v.ti.variant {
                    case rt.Type_Info_Struct: struct_type_info = kind;
                    case rt.Type_Info_Named: struct_type_info = kind.base.variant.(rt.Type_Info_Struct);
                    case: panic(fmt.tprint(kind));
                }

                for name, idx in struct_type_info.names {
                    if name != key_parts[2] do continue;

                    offset := struct_type_info.offsets[idx];
                    field_type_info := struct_type_info.types[idx];
                    ptr = rawptr(uintptr(int(uintptr(ptr)) + int(offset)));

                    // logln("Received Replication field: ", field);

                    // @LEAK
                    wbml.deserialize_into_pointer_with_type_info(transmute([]byte)parts[1], ptr, field_type_info);

                    // logln("Replicated field");
                }
            }
        }
    }
}

update_networked_entities :: proc() {
    @static replication_cache: map[string]any;
    @static fields_to_send: [dynamic]string;

    clear(&fields_to_send);
    @static active_net_id_componenets: [dynamic]Network_Id;
    clear(&active_net_id_componenets);
    ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

    for net_id in active_net_id_componenets {
        for k, v in ecs.component_types {
            if k == typeid_of(ecs.Transform) || k == typeid_of(Network_Id) do continue;
            if !ecs.has_component(net_id.e, k) do continue;
            
            // There should not be components that are not structs
            struct_type_info: rt.Type_Info_Struct;
            #partial switch kind in v.ti.variant {
                case rt.Type_Info_Struct: struct_type_info = kind;
                case rt.Type_Info_Named: struct_type_info = kind.base.variant.(rt.Type_Info_Struct);
                case: panic(fmt.tprint(kind));
            }
            
            for name, idx in struct_type_info.names {
                tag := struct_type_info.tags[idx];

                when #config(HEADLESS, false) {
                    if !strings.contains(tag, "replicate:server") do continue;
                } else {
                    if !strings.contains(tag, "replicate:client") do continue;
                }

                // Create key from Network Id, Component Name, and Field Name
                key := fmt.tprint(net_id.network_id, ":", k, ":", name, ";");

                ptr, ok := ecs.get_component_ptr(net_id.e, k);
                assert(ok);

                offset := struct_type_info.offsets[idx];
                ptr = rawptr(uintptr(int(uintptr(ptr)) + int(offset)));
                field_type_info := struct_type_info.types[idx];

                if key in replication_cache {
                    // compare cached pointer to new
                    equality := mem.compare_ptrs(ptr, replication_cache[key].data, field_type_info.size);
                    if equality == 0 do continue;

                    free(replication_cache[key].data);
                }

                copy_data := rt.mem_alloc(field_type_info.size);
                mem.copy(copy_data, ptr, field_type_info.size);
                replication_cache[key] = any{ copy_data, field_type_info.id };

                // send data
                sb: strings.Builder;
                wbml.serialize_with_type_info(key, ptr, field_type_info, &sb, 0);
                append(&fields_to_send, strings.to_string(sb));
            }
        }
    }

    if len(fields_to_send) == 0 do return;

    replication_packet := Packet{ Replication_Packet{ fields_to_send } };

    when #config(HEADLESS, false) {
        broadcast(&replication_packet);
    } else {
        send_packet(&replication_packet);
    }
    
}

client_entity_receive :: proc(packet: Packet, client_id: int) {
    ep := packet.data.(Entity_Packet);

    handler, exists := get_entity_packet_handler(reflect.union_variant_typeid(ep.data));
    if !exists do return;


    // TODO optimize this
    // Get the entity from the network id
    @static active_net_id_componenets: [dynamic]Network_Id;
    clear(&active_net_id_componenets);
    ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

    for net_id in active_net_id_componenets {
        if net_id.network_id == ep.network_id {
            handler.receive(net_id.e, ep);
            return;
        }
    }

    panic(fmt.tprint("Unabled to find entity: ", ep.network_id));
}

when #config(HEADLESS, false) {
    server_entity_receive :: proc(packet: Packet, client_id: int) {
        ep := packet.data.(Entity_Packet);
        target_entity : Entity;

        handler, exists := get_entity_packet_handler(reflect.union_variant_typeid(ep.data));
        if !exists do return;

        // TODO optimize this
        // Get the entity from the network id
        @static active_net_id_componenets: [dynamic]Network_Id;
        clear(&active_net_id_componenets);
        ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

        for net_id in active_net_id_componenets {
            if net_id.network_id == ep.network_id {
                target_entity = net_id.e;
            }
        }

        handler.receive(target_entity, ep);
    }

    update_client_transform :: proc(entity: ecs.Entity) {
        transform, ok := ecs.get_component(entity, ecs.Transform);
        assert(ok);
        net_id, ok2 := ecs.get_component(entity, Network_Id);
        assert(ok2);

        packet := Packet { Entity_Packet { net_id.network_id, Transform_Packet { transform.position, transform.rotation, transform.scale } } };
        broadcast(&packet);
    }
}

get_entity_from_network_id :: proc(id: int, loc := #caller_location) -> ecs.Entity {
    @static active_net_id_componenets: [dynamic]Network_Id;
    clear(&active_net_id_componenets);
    ecs.get_active_component_storage(Network_Id, &active_net_id_componenets);

    for net_id in active_net_id_componenets {
        if net_id.network_id == id {
            return net_id.e;
        }
    }

    return -1;
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
        Transform_Packet
    }
}

Transform_Packet :: struct {
    position: Vec3,
    rotation: math.Quat,
    scale   : Vec3,
}

// Replication
Replication_Packet :: struct {
    // TODO(jake): don't use strings eventually
    modified_fields: [dynamic]string
}

