package physics

using import "core:fmt"
using import "core:runtime"

using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"
using import    "shared:workbench/math"

import wb       "shared:workbench"

STEP_SIZE : f32 : 0.25;
MAX : f32 : 100;

AStar_Node :: struct {
    position: Vec3,
    parent: Vec3,
    g_cost, h_cost, f_cost: f32,
}

validation_hits : [dynamic]RaycastHit;

is_valid :: proc(pos: Vec3) -> bool {
    clear(&validation_hits);
    hit_num := overlap_point(pos, &validation_hits);
    
    for hit in validation_hits {
        wb.draw_debug_box(hit.intersection_start, Vec3{0.1,0.1,0.1}, COLOR_YELLOW);
    }
    
    return hit_num <= 0;
}

is_destination :: proc(node, dest: Vec3) -> bool {
    return xz_distance(node, dest) <= STEP_SIZE * 2;
}

a_star :: proc(start, goal: Vec3) -> []Vec3 {
    open : [dynamic]AStar_Node;
    closed : [dynamic]AStar_Node;
    
    start_node := AStar_Node{ start, Vec3{F32_MAX,F32_MAX,F32_MAX}, 0, 0, 0 };
    end_node : AStar_Node;
    
    append(&open, start_node);
    
    iters := 0;
    
    outer: for len(open) > 0 {
        iters += 1;
        
        closest_idx := 0;
        lowest_score : f32 = F32_MAX;
        for n, idx in open {
            if n.f_cost < lowest_score {
                lowest_score = n.f_cost;
                closest_idx = idx;
            }
        }
        
        closest_node := open[closest_idx];
        
        if iters > 400 {
            wb.draw_debug_box(closest_node.position, Vec3{0.15,0.15,0.15}, Colorf{0.5,0,0.5,1});
            break;
        }
        
        wb.draw_debug_box(closest_node.position, Vec3{0.1,0.1,0.1}, COLOR_YELLOW);
        if is_destination(closest_node.position, goal) {
            wb.draw_debug_box(closest_node.position, Vec3{0.15,0.15,0.15}, COLOR_BLACK);
            end_node = closest_node;
            break;
        }
        
        append(&closed, closest_node);
        unordered_remove(&open, closest_idx);
        
        successors := get_neighbors(closest_node.position);
        for s in successors {
            s_node := AStar_Node{ 
                s, 
                closest_node.position,
                closest_node.g_cost + xz_distance(s, closest_node.position),
                xz_distance(s, goal), 
                0
            };
            s_node.f_cost = s_node.g_cost + s_node.h_cost;
            
            if !is_valid(s_node.position) do continue;
            
            on, open_contains := find_node_in_array(open[:], s_node.position);
            if open_contains {
                if abs(on.f_cost - s_node.f_cost) < 0.001 {
                    continue;
                }
            }
            
            cn, closed_contains := find_node_in_array(closed[:], s_node.position);
            if closed_contains {
                if abs(cn.f_cost - s_node.f_cost) < 0.001 { 
                    continue;
                }
            }
            
            append(&open, s_node);
        }
    }
    
    path: [dynamic]Vec3;
    for true {
        append(&path, end_node.position);
        //logln(end_node.position, end_node.parent);
        n, exists := find_node_in_array(closed[:], end_node.parent);
        if !exists do break;
        end_node = n;
    }
    //append(&path, goal);
    
    return path[:];
}

xz_distance :: proc(p1, p2: Vec3) -> f32 {
    return distance(p1, p2);
    //d := distance(Vec3{p1.x, 0, p1.y}, Vec3{p2.x, 0, p2.z});
    //return d;
}

find_node_in_array :: proc(arr: []AStar_Node, pos: Vec3) -> (AStar_Node, bool) {
    
    if len(arr) == 0 do return AStar_Node{}, false;
    
    contains := false;
    contained_idx := 0;
    for o, idx in arr {
        if distance(o.position, pos) < 0.001 {
            contains = true;
            contained_idx = idx;
            break;
        }
    }
    
    return arr[contained_idx], contains;
}

get_neighbors :: proc(pt: Vec3) -> [8]Vec3 {
    neighbors : [8]Vec3 = {};
    
    neighbors[0] = pt + Vec3{  STEP_SIZE, 0,  0   };
    neighbors[1] = pt + Vec3{ -STEP_SIZE, 0,  0   };
    neighbors[2] = pt + Vec3{ 0,    0,  STEP_SIZE };
    neighbors[3] = pt + Vec3{ 0,    0, -STEP_SIZE };
    
    neighbors[4] = pt + Vec3{  STEP_SIZE, 0,  STEP_SIZE };
    neighbors[5] = pt + Vec3{ -STEP_SIZE, 0,  STEP_SIZE };
    neighbors[6] = pt + Vec3{ -STEP_SIZE, 0, -STEP_SIZE };
    neighbors[7] = pt + Vec3{  STEP_SIZE, 0, -STEP_SIZE };
    
    return neighbors;
}