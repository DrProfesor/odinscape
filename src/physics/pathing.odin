package physics

import "core:fmt"
import "core:runtime"
import "core:math"
import la "core:math/linalg"

import "shared:wb"
import "shared:wb/profiler"

import "../shared"
import "../entity"

init_pathing :: proc() {

}

update_pathing :: proc(dt: f32) {
    
}

Tri :: struct {
    verts: [3]Vector3,
    id: int,
}

RTree :: struct {
    node_pool: [1024]RTree_Node,
    root_node: ^RTree_Node,
    node_count: int
}

RTree_Node :: struct {
    bounding_min, bounding_max: Vector3,
    children: [dynamic]^RTree_Node,
    node_tris: [dynamic]Tri,
    parent: ^RTree_Node,
}

// TODO(jake): right out of my ass, find a better number
MAX_ENTRIES_IN_NODE :: 100;
generate_rtree :: proc(center: Vector3, search_radius: f32) {
    profiler.TIMED_SECTION();

    using tree: RTree;

    node_pool[node_count] = RTree_Node{ center-search_radius, center+search_radius, {}, {}, nil };
    node_count += 1;
    tree.root_node = &node_pool[0]; 

    bounding_contains_triangle :: proc(min, max: Vector3, tri: Tri) -> (bool, Vector3) {
        tri_center := (tri.verts[0] + tri.verts[1] + tri.verts[2])/3;
        if tri_center.x < min.x || tri_center.y < min.y || tri_center.z < min.z do return false, tri_center;
        if tri_center.x > max.x || tri_center.y > max.y || tri_center.z > max.z do return false, tri_center;
        return true, tri_center;
    }

    insert_triangle :: proc(tree: ^RTree, tree_node: ^RTree_Node, tri: Tri) -> bool {
        assert(tree_node != nil);
        assert(tree != nil);

        if len(tree_node.children) == 0 { // if one is nil they all are
            ok, center := bounding_contains_triangle(tree_node.bounding_min, tree_node.bounding_max, tri);
            if !ok do return false;
            append(&tree_node.node_tris, tri);

            node_center := (tree_node.bounding_min + tree_node.bounding_max)/2;
            if len(tree_node.node_tris) > MAX_ENTRIES_IN_NODE {

                for tri in tree_node.node_tris {
                    tri_center := (tri.verts[0] + tri.verts[1] + tri.verts[2])/3;
                    node : ^RTree_Node;
                    // 0
                    if tri_center.x > node_center.x && tri_center.y > node_center.y && tri_center.z > node_center.z {
                        node = &tree.node_pool[tree.node_count+0];
                    }

                    // 1
                    if tri_center.x > node_center.x && tri_center.y > node_center.y && tri_center.z <= node_center.z {
                        node = &tree.node_pool[tree.node_count+1];
                    }

                    // 2
                    if tri_center.x <= node_center.x && tri_center.y > node_center.y && tri_center.z <= node_center.z {
                        node = &tree.node_pool[tree.node_count+2];
                    }

                    // 3
                    if tri_center.x <= node_center.x && tri_center.y > node_center.y && tri_center.z > node_center.z {
                        node = &tree.node_pool[tree.node_count+3];
                    }

                    // 4
                    if tri_center.x > node_center.x && tri_center.y <= node_center.y && tri_center.z > node_center.z {
                        node = &tree.node_pool[tree.node_count+4];
                    }

                    // 5
                    if tri_center.x > node_center.x && tri_center.y <= node_center.y && tri_center.z <= node_center.z {
                        node = &tree.node_pool[tree.node_count+5];
                    }

                    // 6
                    if tri_center.x <= node_center.x && tri_center.y <= node_center.y && tri_center.z <= node_center.z {
                        node = &tree.node_pool[tree.node_count+6];
                    }

                    // 7
                    if tri_center.x <= node_center.x && tri_center.y <= node_center.y && tri_center.z > node_center.z {
                        node = &tree.node_pool[tree.node_count+7];
                    }

                    assert(node != nil);
                    append(&node.node_tris, tri);
                }

                for i in 0..<8 {
                    tree.node_pool[tree.node_count+i].parent = tree_node;
                    append(&tree_node.children, &tree.node_pool[tree.node_count+i]);
                }

                tree_node.children[0].bounding_max = tree_node.bounding_max;
                tree_node.children[0].bounding_min = node_center;

                tree_node.children[1].bounding_max = {tree_node.bounding_max.x, tree_node.bounding_max.y, node_center.z};
                tree_node.children[1].bounding_min = {node_center.x, node_center.y, tree_node.bounding_min.z};

                tree_node.children[2].bounding_max = {node_center.x, tree_node.bounding_max.y, node_center.z};
                tree_node.children[2].bounding_min = {tree_node.bounding_min.x, node_center.y, tree_node.bounding_min.z};

                tree_node.children[3].bounding_max = {node_center.x, tree_node.bounding_max.y, tree_node.bounding_max.z};
                tree_node.children[3].bounding_min = {tree_node.bounding_min.x, node_center.y, node_center.z};

                tree_node.children[4].bounding_max = {tree_node.bounding_max.x, node_center.y, tree_node.bounding_max.z};
                tree_node.children[4].bounding_min = {node_center.x, tree_node.bounding_min.y, node_center.z};

                tree_node.children[5].bounding_max = {tree_node.bounding_max.x, node_center.y, node_center.z};
                tree_node.children[5].bounding_min = {node_center.x, tree_node.bounding_min.y, tree_node.bounding_min.z};

                tree_node.children[6].bounding_max = node_center;
                tree_node.children[6].bounding_min = tree_node.bounding_min;

                tree_node.children[7].bounding_max = {node_center.x, node_center.y, tree_node.bounding_max.z};
                tree_node.children[7].bounding_min = {tree_node.bounding_min.x, tree_node.bounding_min.y, node_center.z};

                tree.node_count += 8;

                clear(&tree_node.node_tris);
            }
            return true;
        } else {
            for child in tree_node.children {
                if insert_triangle(tree, child, tri) do return true;
            }
            return false;
        }
    }

    for collider in &shared.g_collision_scene.colliders {
        assert(collider.userdata != nil);
        entity := (cast(^entity.Entity)collider.userdata);

        switch kind in collider.info.kind {
            case wb.Box: {
                min := (entity.position - kind.size/2) * entity.scale;
                max := (entity.position + kind.size/2) * entity.scale;

                vert0 := min;
                vert1 := max;
                vert2 := Vector3{vert0.x, vert0.y, vert1.z};
                vert3 := Vector3{vert0.x, vert1.y, vert0.z};
                vert4 := Vector3{vert1.x, vert0.y, vert0.z};
                vert5 := Vector3{vert0.x, vert1.y, vert1.z};
                vert6 := Vector3{vert1.x, vert0.y, vert1.z};
                vert7 := Vector3{vert1.x, vert1.y, vert0.z};

                insert_triangle(&tree, &node_pool[0 ], Tri{{ vert0, vert7, vert4 }, entity.id});
                insert_triangle(&tree, &node_pool[1 ], Tri{{ vert0, vert3, vert7 }, entity.id});
                insert_triangle(&tree, &node_pool[2 ], Tri{{ vert5, vert1, vert3 }, entity.id});
                insert_triangle(&tree, &node_pool[3 ], Tri{{ vert3, vert1, vert7 }, entity.id});
                insert_triangle(&tree, &node_pool[4 ], Tri{{ vert7, vert1, vert4 }, entity.id});
                insert_triangle(&tree, &node_pool[5 ], Tri{{ vert4, vert1, vert6 }, entity.id});
                insert_triangle(&tree, &node_pool[6 ], Tri{{ vert5, vert3, vert2 }, entity.id});
                insert_triangle(&tree, &node_pool[7 ], Tri{{ vert2, vert3, vert0 }, entity.id});
                insert_triangle(&tree, &node_pool[8 ], Tri{{ vert0, vert4, vert2 }, entity.id});
                insert_triangle(&tree, &node_pool[9 ], Tri{{ vert2, vert4, vert6 }, entity.id});
                insert_triangle(&tree, &node_pool[10], Tri{{ vert1, vert5, vert2 }, entity.id});
                insert_triangle(&tree, &node_pool[11], Tri{{ vert6, vert1, vert2 }, entity.id});
                node_count += 12;
            }
            case wb.Collision_Model: {
                mm := wb.construct_model_matrix(entity.position, entity.scale, entity.rotation);
                // mm := la.matrix4_from_trs(entity.position, entity.rotation, entity.scale);
                for mesh in wb.g_models[kind.model_id].meshes {
                    for tri in mesh.triangles {
                        _t1 := mul(mm, Vector4{tri[0].x, tri[0].y, tri[0].z, 1});
                        _t2 := mul(mm, Vector4{tri[1].x, tri[1].y, tri[1].z, 1});
                        _t3 := mul(mm, Vector4{tri[2].x, tri[2].y, tri[2].z, 1});
                        insert_triangle(&tree, &node_pool[0], Tri{{{_t1.x, _t1.y, _t1.z}, {_t2.x, _t2.y, _t2.z}, {_t3.x, _t3.y, _t3.z}}, entity.id});
                    }
                }
            }
            case: panic(fmt.tprint(kind));
        }
    }
}

RTree_Hit :: struct {
    pos: Vector3,
    tri: [3]Vector3,
    id: int,
}

raycast_rtree :: proc{raycast_rtree_single, raycast_rtree_multi};

raycast_rtree_single :: proc(tree: ^RTree, origin, direction: Vector3) -> (bool, RTree_Hit) {
    assert(tree != nil);

    profiler.TIMED_SECTION();
    _recurse :: proc(node: ^RTree_Node, origin, direction: Vector3) -> (bool, RTree_Hit) {
        assert(node != nil);

        if len(node.children) > 0 {
            for child in node.children {
                hit, info := _recurse(child, origin, direction);
                if hit do return hit, info;
            }
            return false, {};
        } 

        // Check bounding box
        hit, _ := wb.cast_line_box(origin, direction, node.bounding_min, node.bounding_max);
        if !hit do return false, {};

        // Iterate tris
        for tri in node.node_tris {
            hit, whre := wb.cast_line_triangle(origin, direction, tri.verts[0], tri.verts[1], tri.verts[2]);
            if hit do return true, RTree_Hit{whre, tri.verts, tri.id};
        }

        return false, {};
    }

    return _recurse(tree.root_node, origin, direction);
}

raycast_rtree_multi :: proc(tree: ^RTree, origin, direction: Vector3, hits: ^[dynamic]RTree_Hit, max_hits := 10) -> int {
    origin := origin;

    clear(hits);

    for _ in 0..<max_hits {
        hit, info := raycast_rtree(tree, origin, direction);

        if !hit do return len(hits);

        origin = info.pos + direction * math.F32_EPSILON;

        append(hits, info);
    }

    return len(hits);
}

AStar_Node :: struct {
    position: Vector3,
    parent: ^AStar_Node,
    g_cost, h_cost, f_cost: f32,
}

is_valid :: proc(pos: Vector3) -> bool {
    // hit, _ := raycast_rtree(&tree, pos, Vector3{0, -1, 0});
    return false;
}

a_star :: proc(_start, _goal: Vector3, step_size: f32) -> []Vector3 {
    profiler.TIMED_SECTION();
    start := Vector3{_start.x, 0, _start.z};
    goal := Vector3{_goal.x, 0, _goal.z};

    @static all_nodes: [2048]AStar_Node;
    last_node_idx := 0;
    open: [dynamic]^AStar_Node;
    closed: [dynamic]^AStar_Node;
    defer {
        delete(open);
        delete(closed);
    }

    if !is_valid(start) || !is_valid(goal) {
        return {};
    }

    end_node: ^AStar_Node;
    all_nodes[last_node_idx] = AStar_Node{ goal, nil, 0, 0, 0 };
    append(&open, &all_nodes[last_node_idx]);
    last_node_idx += 1;

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
                all_nodes[last_node_idx] = s_node;
                append(&open, &all_nodes[last_node_idx]);
                last_node_idx += 1;
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

smooth_a_star :: proc(start, goal: Vector3, step_size: f32) -> []Vector3 {
    profiler.TIMED_SECTION();
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