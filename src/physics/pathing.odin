package physics

using import "core:fmt"
using import "core:runtime"

using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"
using import    "shared:workbench/math"

import wb       "shared:workbench"

STEP_SIZE : f32 : 1;
MAX : f32 : 100;

AStar_Node :: struct {
    position: Vec3,
    parent: ^AStar_Node,
    g_cost, f_cost: f32,
}

validation_hits : [dynamic]RaycastHit;

is_valid :: proc(pos: Vec3) -> bool {
    clear(&validation_hits);
    hit_num := overlap_point(pos, &validation_hits);
    
    for hit in validation_hits {
        logln(hit.e);
        wb.draw_debug_box(hit.intersection_start, Vec3{0.1,0.1,0.1}, COLOR_YELLOW);
    }
    
    return hit_num <= 0;
}

is_destination :: proc(node, dest: Vec3) -> bool {
    return xz_dist(node, dest) < STEP_SIZE;
}

calculate_h_cost :: proc(current, dest: AStar_Node) -> f32 {
    return sqrt((current.position.x - dest.position.x) * (current.position.x - dest.position.x) + 
                (current.position.y - dest.position.y) * (current.position.y - dest.position.y));
}

a_star :: proc(start, goal: Vec3) -> []Vec3 {
    open_set : [dynamic]AStar_Node;
    start_node := AStar_Node{start, nil, 0, 0};
    append(&open_set, start_node);
    
    if is_destination(start, goal) {
        logln("At destination");
        return {start};
    }
    
    if !is_valid(goal) {
        logln("Invalid destination");
        return {start};
    }
    
    closed_set : [dynamic]AStar_Node;
    
    current : ^AStar_Node = nil;
    outer: for len(open_set) > 0 {
        lowest_cost : f32 = F32_MAX;
        lowest_idx := 0;
        for idx := 0; idx < len(open_set); idx += 1 {
            node := open_set[idx];
            if node.f_cost < lowest_cost {
                lowest_cost = node.f_cost;
                current = &open_set[idx];
                lowest_idx = idx;
            }
        }
        
        if is_destination(current.position, goal) {
            break;
        }
        
        append(&closed_set, current^);
        unordered_remove(&open_set, lowest_idx);
        
        for neighbor, i in get_neighbors(current.position) {
            found_in_closed := false;
            for o in closed_set {
                if distance(o.position, neighbor) < 0.001 {
                    found_in_closed = true;
                    break;
                }
            }
            
            if found_in_closed || !is_valid(neighbor) {
                continue;
            }
            
            found := false;
            found_idx := 0;
            for o, idx in open_set {
                if distance(o.position, neighbor) < 0.001 {
                    found = true;
                    found_idx = idx;
                    break;
                }
            }
            
            total_cost := current.g_cost;
            if i < 4 do total_cost += 10;
            else do total_cost += 14;
            
            if !found {
                n_node := AStar_Node{neighbor, current, 0, 0};
                n_node.g_cost = total_cost;
                n_node.f_cost = xz_dist(neighbor, goal) * 10;
                append(&open_set, n_node);
            } else if total_cost <  open_set[found_idx].g_cost {
                s := open_set[found_idx];
                
                s.parent = current;
                s.g_cost = total_cost;
                
                open_set[found_idx] = s;
            }
            
        }
    }
    
    path : [dynamic]Vec3;
    for current != nil {
        append(&path, current.position);
        current = current.parent;
    }
    
    return path[:];
}

xz_dist :: proc(p1, p2: Vec3) -> f32 {
    return distance(Vec3{p1.x, 0, p1.y}, Vec3{p2.x, 0, p2.z});
}


get_neighbors :: proc(pt: Vec3) -> []Vec3 {
    neighbors : [8]Vec3 = {};
    
    neighbors[0] = pt + Vec3{  STEP_SIZE, 0,  0   };
    neighbors[1] = pt + Vec3{ -STEP_SIZE, 0,  0   };
    neighbors[2] = pt + Vec3{ 0,    0,  STEP_SIZE };
    neighbors[3] = pt + Vec3{ 0,    0, -STEP_SIZE };
    
    neighbors[4] = pt + Vec3{  STEP_SIZE, 0,  STEP_SIZE };
    neighbors[5] = pt + Vec3{ -STEP_SIZE, 0,  STEP_SIZE };
    neighbors[6] = pt + Vec3{ -STEP_SIZE, 0, -STEP_SIZE };
    neighbors[7] = pt + Vec3{  STEP_SIZE, 0, -STEP_SIZE };
    
    return neighbors[:];
}