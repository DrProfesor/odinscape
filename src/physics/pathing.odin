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

is_valid :: proc(pos: Vec3) -> bool {
    return overlap_point(pos) <= 0;
}

is_destination :: proc(node, dest: Vec3) -> bool {
    return distance(node, dest) <= STEP_SIZE * 2;
}

a_star :: proc(start, goal: Vec3) -> []Vec3 {
    open : [dynamic]AStar_Node;
    closed : [dynamic]AStar_Node;
    
    start_node := AStar_Node{ start, Vec3{F32_MAX,F32_MAX,F32_MAX}, 0, 0, 0 };
    end_node : AStar_Node;
    
    append(&open, start_node);
    
    outer: for len(open) > 0 {
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
        
        successors := get_neighbors_2d(closest_node.position);
        for s in successors {
            s_node := AStar_Node{ 
                s, 
                closest_node.position,
                closest_node.g_cost + distance(s, closest_node.position),
                distance(s, goal), 
                0
            };
            s_node.f_cost = s_node.g_cost + s_node.h_cost;
            
            if !is_valid(s_node.position) do continue;
            
            _, open_contains, _ := find_node_in_array(open[:], s_node.position);
            if open_contains do continue;
            
            cn, closed_contains, idx := find_node_in_array(closed[:], s_node.position);
            if closed_contains {
                if cn.f_cost <=  s_node.f_cost { 
                    continue;
                } else {
                    n := closed[idx];
                    n.parent = s_node.parent;
                    n.f_cost = s_node.f_cost;
                    closed[idx] = n;
                }
            } else {
                append(&open, s_node);
            }
        }
    }
    
    path: [dynamic]Vec3;
    for true {
        append(&path, end_node.position);
        n, exists, idx := find_node_in_array(closed[:], end_node.parent);
        if !exists do break;
        end_node = n;
    }
    
    return path[:];
}

find_node_in_array :: proc(arr: []AStar_Node, pos: Vec3) -> (AStar_Node, bool, int) {
    
    if len(arr) == 0 do return AStar_Node{}, false, -1;
    
    contains := false;
    contained_idx := 0;
    for o, idx in arr {
        if distance(o.position, pos) < 0.001 {
            contains = true;
            contained_idx = idx;
            break;
        }
    }
    
    return arr[contained_idx], contains, contained_idx;
}

get_neighbors_2d :: proc(pt: Vec3) -> [8]Vec3 {
    neighbors : [8]Vec3 = {};
    
    i := 0;
    for x := -1; x < 2; x += 1 {
        for z := -1; z < 2; z += 1 {
            if x == 0 && z == 0 do continue;
            
            neighbors[i] = pt + Vec3{STEP_SIZE * f32(x), 0, STEP_SIZE * f32(z)};
            i += 1;
        }
    }
    
    return neighbors;
}

get_neighbors_3d :: proc(pt: Vec3) -> [26]Vec3 {
    neighbors : [26]Vec3 = {};
    
    i := 0;
    for x := -1; x < 2; x += 1 {
        for y := -1; y < 2; y += 1 {
            for z := -1; z < 2; z += 1 {
                if x == 0 && y == 0 && z == 0 do continue;
                neighbors[i] = pt + Vec3{STEP_SIZE * f32(x), STEP_SIZE * f32(y), STEP_SIZE * f32(z)};
                i += 1;
            }
        }
    }
    
    return neighbors;
}