package physics

import "core:fmt"
import "core:runtime"

import "shared:wb"
import log "shared:wb/logging"

Vector3 :: wb.Vector3;

AStar_Node :: struct {
    position: Vector3,
    parent: ^AStar_Node,
    g_cost, h_cost, f_cost: f32,
}

is_valid :: proc(pos: Vector3) -> bool {
    return true;
    // return overlap_point(pos) <= 0;
}

a_star :: proc(_start, _goal: Vector3, step_size: f32) -> []Vector3 {

    start := Vector3{_start.x, 0, _start.z};
    goal := Vector3{_goal.x, 0, _goal.z};

    open: [dynamic]^AStar_Node;
    closed: [dynamic]^AStar_Node;
    defer {
        for n in open do free(n);
        for n in closed do free(n);
        delete(open);
        delete(closed);
    }

    if !is_valid(start) || !is_valid(goal) {
        return {};
    }

    start_node := AStar_Node{ goal, nil, 0, 0, 0 };
    end_node: ^AStar_Node;
    append(&open, new_clone(start_node));

    outer: for len(open) > 0 {
        closest_node: ^AStar_Node;
        closest_idx := -1;
        for node, i in open {
            if closest_node == nil || node.f_cost < closest_node.f_cost {
                closest_node = node;
                closest_idx = i;
            }
        }

        assert(closest_node != nil);
        if distance(closest_node.position, start) <= step_size {
            end_node = closest_node;
            break;
        }

        append(&closed, closest_node);
        unordered_remove(&open, closest_idx);

        successors := get_neighbors_2d(closest_node.position, step_size);
        for s in successors {
            if !is_valid(s) do continue;
            _, open_contains, _ := find_node_in_array(open[:], s);
            if open_contains do continue;
            grounded_s := Vector3{ s.x, 0, s.z };
            s_node := AStar_Node { grounded_s, closest_node, closest_node.g_cost + distance(grounded_s, closest_node.position), distance(grounded_s, start), 0 };
            s_node.f_cost = s_node.g_cost + s_node.h_cost;

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
                append(&open, new_clone(s_node));
            }
        }
    }

    path: [dynamic]Vector3;
    for true {
        if end_node == nil do break;
        append(&path, end_node.position);
        end_node = end_node.parent;
    }

    return path[:];
}

// a_star :: proc(start, goal: Vector3, step_size: f32) -> []Vector3 {
//     profiler.TIMED_SECTION(&wb.wb_profiler, "Raw A*");
//     open : [dynamic]AStar_Node;
//     closed : [dynamic]AStar_Node;
//     defer delete(open);
//     defer delete(closed);

//     start_node := AStar_Node{ start, Vector3{max(f32),max(f32),max(f32)}, 0, 0, 0 };
//     end_node : AStar_Node;

//     append(&open, start_node);

//     outer: for len(open) > 0 {
//         closest_idx := 0;
//         lowest_score : f32 = max(f32);
//         for n, idx in open {
//             if n.f_cost < lowest_score {
//                 lowest_score = n.f_cost;
//                 closest_idx = idx;
//             }
//         }

//         closest_node := open[closest_idx];

//         if distance(closest_node.position, goal) <= step_size{
//             end_node = closest_node;
//             break;
//         }

//         append(&closed, closest_node);
//         unordered_remove(&open, closest_idx);

//         successors := get_neighbors_3d(closest_node.position, step_size);
//         for s in successors {
//             s_node := AStar_Node{
//                 s,
//                 closest_node.position,
//                 closest_node.g_cost + distance(s, closest_node.position),
//                 distance(s, goal),
//                 0
//             };
//             s_node.f_cost = s_node.g_cost + s_node.h_cost;

//             if !is_valid(s_node.position) do continue;

//             _, open_contains, _ := find_node_in_array(open[:], s_node.position);
//             if open_contains do continue;

//             cn, closed_contains, idx := find_node_in_array(closed[:], s_node.position);
//             if closed_contains {
//                 if cn.f_cost <=  s_node.f_cost {
//                     continue;
//                 } else {
//                     n := closed[idx];
//                     n.parent = s_node.parent;
//                     n.f_cost = s_node.f_cost;
//                     closed[idx] = n;
//                 }
//             } else {
//                 append(&open, s_node);
//             }
//         }
//     }

//     path: [dynamic]Vector3;
//     for true {
//         append(&path, end_node.position);
//         n, exists, idx := find_node_in_array(closed[:], end_node.parent);
//         if !exists do break;
//         end_node = n;
//     }

//     return path[:];
// }

// sees_start := raycast(s_node.position, start - s_node.position) == 0;
// if sees_start {
//     wb.draw_debug_line(start, s_node.position, sees_start ? {0, 1, 0, 1} : {1, 0, 0, 1});
//     s := new_clone(s_node);
//     append(&closed, s);
//     end_node = new_clone(AStar_Node{ start, s, 0, 0, 0 });
//     break outer;
// } else {

smooth_a_star :: proc(start, goal: Vector3, step_size: f32) -> []Vector3 {
    raw_path := a_star(start, goal, step_size);
    size := len(raw_path);
    if size <= 2 do return raw_path;
    points := make([dynamic]Vector3, 0, 10);

    i := 0;
    check_point := start;
    append(&points, check_point);
    current_point := raw_path[i]; i+=1;
    for i < size-2 {
        walkable := raycast(check_point, current_point - check_point) == 0;
        if !walkable {
            check_point = raw_path[i-1];
            append(&points, check_point);
        }
        i+=1;
        current_point = raw_path[i];
    }

    append(&points, raw_path[size-1]);

    return points[:];
}

find_node_in_array :: proc(arr: []^AStar_Node, pos: Vector3) -> (^AStar_Node, bool, int) {

    if len(arr) == 0 do return nil, false, -1;

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

get_neighbors_2d :: proc(pt: Vector3, step_size: f32) -> [8]Vector3 {
    neighbors : [8]Vector3 = {};

    i := 0;
    for x := -1; x < 2; x += 1 {
        for z := -1; z < 2; z += 1 {
            if x == 0 && z == 0 do continue;

            neighbors[i] = pt + Vector3{step_size * f32(x), 0, step_size * f32(z)};
            i += 1;
        }
    }

    return neighbors;
}

get_neighbors_3d :: proc(pt: Vector3, step_size: f32) -> [26]Vector3 {
    neighbors : [26]Vector3 = {};

    i := 0;
    for x := -1; x < 2; x += 1 {
        for y := -1; y < 2; y += 1 {
            for z := -1; z < 2; z += 1 {
                if x == 0 && y == 0 && z == 0 do continue;
                neighbors[i] = pt + Vector3{step_size * f32(x), step_size * f32(y), step_size * f32(z)};
                i += 1;
            }
        }
    }

    return neighbors;
}

distance :: inline proc(x, y: $T/[$N]$E) -> E {
    sqr_dist := sqr_distance(x, y);
    return wb.sqrt(sqr_dist);
}

sqr_distance :: inline proc(x, y: $T/[$N]$E) -> E {
    diff := x - y;
    sum: E;
    for i in 0..<N {
        sum += diff[i] * diff[i];
    }
    return sum;
}