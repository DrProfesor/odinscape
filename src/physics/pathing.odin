package physics

import "core:fmt"
import "core:runtime"

import wb       "shared:workbench"
import log "shared:workbench/logging"
import "shared:workbench/math"
import "shared:workbench/types"

AStar_Node :: struct {
    position: Vec3,
    parent: Vec3,
    g_cost, h_cost, f_cost: f32,
}

is_valid :: proc(pos: Vec3) -> bool {
    return overlap_point(pos) <= 0;
}

a_star :: proc(start, goal: Vec3, step_size: f32) -> []Vec3 {
    open : [dynamic]AStar_Node;
    closed : [dynamic]AStar_Node;
    defer delete(open);
    defer delete(closed);

    start_node := AStar_Node{ start, Vec3{max(f32),max(f32),max(f32)}, 0, 0, 0 };
    end_node : AStar_Node;

    append(&open, start_node);

    outer: for len(open) > 0 {
        closest_idx := 0;
        lowest_score : f32 = max(f32);
        for n, idx in open {
            if n.f_cost < lowest_score {
                lowest_score = n.f_cost;
                closest_idx = idx;
            }
        }

        closest_node := open[closest_idx];

        if distance(closest_node.position, goal) <= step_size{
            end_node = closest_node;
            break;
        }

        append(&closed, closest_node);
        unordered_remove(&open, closest_idx);

        successors := get_neighbors_3d(closest_node.position, step_size);
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

smooth_a_star :: proc(start, goal: Vec3, step_size: f32, granularity : f32 = 10) -> []Vec3 {
    raw_path := a_star(start, goal, step_size);
    size := len(raw_path);
    if size <= 2 do return raw_path;
    points := make([dynamic]Vec3, 0, );
    append(&points, raw_path[size-1]);

    i := size - 1;
    check_point := raw_path[i]; i-=1;
    current_point := raw_path[i]; i-=1;
    for i >= 1 {
        walkable := true;
        dir := math.norm(current_point - check_point);
        for dist in 0..granularity {
            pos := current_point + (dir*step_size) * (dist / granularity);
            wb.draw_debug_box(pos, Vec3{0.1,0.1,0.1}, {1,0,0,1});
            if !is_valid(pos) {
                walkable = false;
                break;
            }

        }

        if !walkable {
            append(&points, raw_path[i]);
        }

        i-=1;
        current_point = raw_path[i];
    }

    append(&points, raw_path[0]);

    return points[:];
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

get_neighbors_2d :: proc(pt: Vec3, step_size: f32) -> [8]Vec3 {
    neighbors : [8]Vec3 = {};

    i := 0;
    for x := -1; x < 2; x += 1 {
        for z := -1; z < 2; z += 1 {
            if x == 0 && z == 0 do continue;

            neighbors[i] = pt + Vec3{step_size * f32(x), 0, step_size * f32(z)};
            i += 1;
        }
    }

    return neighbors;
}

get_neighbors_3d :: proc(pt: Vec3, step_size: f32) -> [26]Vec3 {
    neighbors : [26]Vec3 = {};

    i := 0;
    for x := -1; x < 2; x += 1 {
        for y := -1; y < 2; y += 1 {
            for z := -1; z < 2; z += 1 {
                if x == 0 && y == 0 && z == 0 do continue;
                neighbors[i] = pt + Vec3{step_size * f32(x), step_size * f32(y), step_size * f32(z)};
                i += 1;
            }
        }
    }

    return neighbors;
}