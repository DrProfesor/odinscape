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
    g_cost, h_cost, f_cost: f32,
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

a_star :: proc(start, goal: Vec3) -> []Vec3 {
    open : [dynamic]AStar_Node;
    closed : [dynamic]AStar_Node;
    
    start_node := AStar_Node{ start, nil, 0, 0, 0 };
    end_node : AStar_Node;
    
    append(&open, start_node);
    
    outer: for len(open) > 0 {
        logln("len: ", len(open));
        closest_idx := 0;
        lowest_score : f32 = F32_MAX;
        for n, idx in open {
            if n.f_cost < lowest_score {
                lowest_score = n.f_cost;
                closest_idx = idx;
            }
        }
        
        closest_node := open[closest_idx];
        
        if is_destination(closest_node.position, goal) {
            end_node = closest_node;
            break;
        }
        
        append(&closed, closest_node);
        unordered_remove(&open, closest_idx);
        
        successors := get_neighbors(closest_node.position);
        for s in successors {
            s_node := AStar_Node{ 
                s, 
                &closed[len(closed)-1],
                closest_node.g_cost + distance(s, closest_node.position),
                distance(s, goal), 
                0
            };
            s_node.f_cost = s_node.g_cost + s_node.h_cost;
            
            if !is_valid(s_node.position) do continue;
            
            if is_destination(s_node.position, goal) {
                end_node = s_node;
                break outer;
            }
            
            contains := false;
            contained_idx := 0;
            for o, idx in open {
                if distance(o.position, s_node.position) < 0.001 {
                    contains = true;
                    contained_idx = idx;
                    break;
                }
            }
            
            if contains && open[contained_idx].f_cost < s_node.f_cost do continue;
            
            contains = false;
            contained_idx = 0;
            for o, idx in closed {
                if distance(o.position, s_node.position) < 0.001 {
                    contains = true;
                    contained_idx = idx;
                    break;
                }
            }
            
            if contains && closed[contained_idx].f_cost < s_node.f_cost do continue;
            
            append(&open, s_node);
        }
    }
    
    path: [dynamic]Vec3;
    for true {
        append(&path, end_node.position);
        logln("in final loop");
        
        if end_node.parent == nil do break;
        
        end_node = end_node.parent^;
    }
    append(&path, goal);
    
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