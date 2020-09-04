package net

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:reflect"
import "core:mem"
import rt "core:runtime"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/math"
import "shared:wb/wbml"

import "../entity"

handle_replication :: proc(packet: Packet, client_id: int) {
    replication_data := packet.data.(Replication_Packet);
    for field in replication_data.modified_fields {
        parts := strings.split(field, ";");
        key_parts := strings.split(parts[0], ":");
        target_network_id, _ := strconv.parse_int(key_parts[0]);

        for entity in &entity.all_entities {
            if entity.network_id != target_network_id do continue;

            // probably look for replication fields and validate sender can control 

            type_info := type_info_of(typeid_of(type_of(entity)));
            struct_type_info: rt.Type_Info_Struct;
            #partial switch kind in type_info.variant {
                case rt.Type_Info_Struct: struct_type_info = kind;
                case rt.Type_Info_Named: struct_type_info = kind.base.variant.(rt.Type_Info_Struct);
                case: panic(fmt.tprint(kind));
            }

            for name, idx in struct_type_info.names {
                if name != key_parts[1] do continue;

                offset := struct_type_info.offsets[idx];
                field_type_info := struct_type_info.types[idx];
                ptr := rawptr(uintptr(int(uintptr(&entity)) + int(offset)));
                
                // @LEAK
                wbml.deserialize_into_pointer_with_type_info(transmute([]byte)parts[1], ptr, field_type_info);
            }
        }
    }
}

update_networked_entities :: proc() {
    @static replication_cache: map[string]any;
    @static fields_to_send: [dynamic]string;

    clear(&fields_to_send);

    for entity in &entity.all_entities {
        if entity.id < 0 do continue;
        if entity.network_id < 0 do continue;
        
        type_info := type_info_of(typeid_of(type_of(entity)));
        struct_type_info: rt.Type_Info_Struct;
        #partial switch kind in type_info.variant {
            case rt.Type_Info_Struct: struct_type_info = kind;
            case rt.Type_Info_Named: struct_type_info = kind.base.variant.(rt.Type_Info_Struct);
            case: panic(fmt.tprint(kind));
        }

        for name, idx in struct_type_info.names {
            tags := struct_type_info.tags[idx];

            // check for the replicate tag
            // the replicate tage must be marked as server or client
            // the one that it is marked as determines who has control of that field
            when #config(HEADLESS, false) {
                if !strings.contains(tags, "replicate:server") do continue;
            } else {
                if !strings.contains(tags, "replicate:client") do continue;
            }

            // Create key from Network Id, Component Name, and Field Name
            key := fmt.tprint(args={entity.network_id, ":", name}, sep="");

            offset := struct_type_info.offsets[idx];
            // note(jake): cast to int, offset, cast back to pointer
            ptr := rawptr(uintptr( int(uintptr(&entity)) + int(offset)) ); 
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

    if len(fields_to_send) == 0 do return;

    replication_packet := Packet{ Replication_Packet{ fields_to_send } };

    when #config(HEADLESS, false) {
        broadcast(&replication_packet);
    } else {
        send_packet(&replication_packet);
    }
    
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

