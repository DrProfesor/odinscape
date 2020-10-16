package util

import "core:fmt"
import "core:time"
import "core:strings"
import "core:math/rand"

tprint :: proc(_args: ..any) -> string {
	return fmt.tprint(args=_args, sep="");
}

Uuid :: struct #raw_union {
    using _: struct #packed {
        time_low : u32,
        time_mid : u16,
        time_hi_and_version : u16,
        clock_seq_hi_and_res_clock_seq_low : u16,
        node : [3]u16,
    },
    raw :u128,
}

#assert(size_of(Uuid) == size_of(u128));

uuid_create :: proc(version : u16 = 0) -> Uuid {
    // RFC 4122 - Loosely based on version 4.2
    v := version == 0 ? u16(rand.uint32()) : version; // if no version passed in, generate a random one
    cs := u16(rand.uint32());
    n : [3]u16 = { u16(rand.uint32()), u16(rand.uint32()), u16(rand.uint32()) };
    t := time.now();
    
    u : Uuid;
    u.time_low = u32(t._nsec & 0x00000000ffffffff);
    u.time_mid = u16((t._nsec & 0x000000ffff000000) >> 24);
    u.time_hi_and_version = u16(u16(t._nsec >> 52) | v);
    u.clock_seq_hi_and_res_clock_seq_low = cs;
    u.node = n;
    
    return u;
}

uuid_create_string :: proc(version : u16 = 0, allocator := context.allocator) -> string {
    using strings;
    
    uuid := uuid_create(version);
    
    sb := make_builder(allocator);
    grow_builder(&sb, 38);
    defer destroy_builder(&sb);
    
    fmt.sbprintf(&sb, "%08x-%04x-%04x-%04x-%04x%04x%04x",
                 uuid.time_low, uuid.time_mid, uuid.time_hi_and_version, uuid.clock_seq_hi_and_res_clock_seq_low,
                 uuid.node[0], uuid.node[1], uuid.node[2]);
    
    return to_string(sb);
}