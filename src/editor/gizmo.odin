package editor

import "shared:wb"
import coll "shared:wb/collision"
import "shared:wb/basic"
import "shared:wb/imgui"

import "../shared"
import "../game"

direction_unary := [3]Vector3{ Vector3{1,0,0}, Vector3{0,1,0}, Vector3{0,0,1}  };
direction_color := [4]Vector4{ Vector4{1,0,0,1}, Vector4{0,1,0,1}, Vector4{0,0,1,1}, Vector4{1,1,1,1} };
selection_color := Vector4{1,1,0.1,1};

Gizmo_State :: struct {
    size: f32,
    is_manipulating: bool,
    last_point: Vector3,
    move_type: Move_Type,
    hovered_type: Move_Type,
    mouse_pixel_position_on_rotate_clicked: Vector2,

    position_on_move_clicked: Vector3,
    scale_on_scale_clicked: Vector3,
    rotation_on_rotate_clicked: Quaternion,
}

operation: Operation;
manipulation_mode: Manipulation_Mode;
gizmo_mesh: wb.Model;

TRANSLATE_PLANE_OFFSET :: 0.5;
TRANSLATE_PLANE_SIZE :: 0.25;

gizmo_color_buffer: wb.Texture;
gizmo_depth_buffer: wb.Texture;

init_gizmo :: proc() {
    gizmo_color_buffer, gizmo_depth_buffer = wb.create_color_and_depth_buffers(wb.main_window.width_int, wb.main_window.height_int, .R8G8B8A8_UINT);
    wb.init_model(&gizmo_mesh);
    wb.add_mesh_to_model(&gizmo_mesh, []wb.Vertex{}, []u32{}, "gizmo_mtl");
}

gizmo_new_frame :: proc() {
    clear(&im_gizmos);
}

Gizmo_Result :: union {
    Gizmo_Move,
    Gizmo_Rotate,
    Gizmo_Scale,
}
Gizmo_Move :: struct {
    from, to: Vector3,
}
Gizmo_Rotate :: struct {
    from, to: Quaternion,
}
Gizmo_Scale :: struct {
    from, to: Vector3,
}

gizmo_manipulate :: proc(position: ^Vector3, scale: ^Vector3, rotation: ^Quaternion, camera: ^wb.Camera, using gizmo_state: ^Gizmo_State) -> Gizmo_Result {
    rotation^ = quat_norm(rotation^);

    was_move_type := move_type;
    if wb.get_global_input_up(.Mouse_Left) {
        move_type = .NONE;
    }

    hovered_type = move_type;

    origin := position^;

    direction_to_camera := norm(origin - g_editor_camera.position);

    plane_dist := dot(-direction_to_camera, (g_editor_camera.position - origin)) * -1;
    translation_vec := -direction_to_camera * plane_dist;
    plane_point := origin + translation_vec;

    size = length(plane_point - g_editor_camera.position) * 0.075;

    // todo(josh): remove hardcoded Mouse_Right thing. this is only here because the scene view in Mathy Game uses right click to know when to move the camera in edit mode
    if move_type == .NONE && !wb.get_global_input(.Mouse_Right) {
        if wb.get_input_down(.Q, true) do if manipulation_mode == .World do manipulation_mode = .Local else do manipulation_mode = .World;
        if wb.get_input_down(.W, true) do operation = .Translate;
        if wb.get_input_down(.E, true) do operation = .Rotate;
        if wb.get_input_down(.R, true) do operation = .Scale;
        if wb.get_input_down(.T, true) do operation = .None;
    }


    unit_mouse_pos := g_game_view_mouse_pos / {shared.WINDOW_SIZE_X, shared.WINDOW_SIZE_Y};
    mouse_world := wb.get_mouse_world_position(camera, unit_mouse_pos);
    mouse_direction := wb.get_mouse_direction_from_camera(camera, unit_mouse_pos);
    #partial switch operation {
        case .Translate: {
            was_active := move_type != .NONE;
            // arrows
            if move_type == .NONE {
                current_closest := max(f32);
                outer: for i in 0..2 {
                    center_on_screen := wb.world_to_unit(camera, origin);
                    tip_on_screen := wb.world_to_unit(camera, origin + rotated_direction(rotation^, direction_unary[i]) * size);

                    p := coll.closest_point_on_line(to_vec3(unit_mouse_pos), center_on_screen, tip_on_screen);
                    dist := length(p - to_vec3(unit_mouse_pos));
                    if dist < size * 0.005 && dist < current_closest {
                        current_closest = dist;
                        hovered_type = Move_Type.MOVE_X + Move_Type(i);
                        if wb.get_global_input_down(.Mouse_Left, true) {
                            gizmo_state.position_on_move_clicked = position^;
                            move_type = hovered_type;
                        }
                    }
                }
            }

            // planes
            if move_type == .NONE {
                for i in  0..2 {
                    normal := rotated_direction(rotation^, direction_unary[ i      ]) * size;
                    dir_x  := rotated_direction(rotation^, direction_unary[(i+1) %3]) * size;
                    dir_y  := rotated_direction(rotation^, direction_unary[(i+2) %3]) * size;

                    quad_center := origin + (dir_y + dir_x) * TRANSLATE_PLANE_OFFSET;
                    intersect_point, ok := coll.plane_intersect(quad_center, normal, g_editor_camera.position, mouse_direction);
                    if length(intersect_point - quad_center) < (TRANSLATE_PLANE_SIZE * size) { // todo(josh): for the planes we are just doing a circle check right now. kinda dumb but it's easy :)
                        hovered_type = Move_Type.MOVE_YZ + Move_Type(i);
                        if wb.get_global_input_down(.Mouse_Left, true) {
                            gizmo_state.position_on_move_clicked = position^;
                            move_type = hovered_type;
                            break;
                        }
                    }
                }
            }


            if move_type != .NONE {
                plane_norm: Vector3;
                #partial
                switch move_type {
                    case .MOVE_X:  plane_norm = rotated_direction(rotation^, Vector3{0, 0, 1});
                    case .MOVE_Y:  plane_norm = rotated_direction(rotation^, Vector3{0, 0, 1});
                    case .MOVE_Z:  plane_norm = rotated_direction(rotation^, Vector3{1, 0, 0});
                    case .MOVE_XY: plane_norm = rotated_direction(rotation^, Vector3{0, 0, 1});
                    case .MOVE_YZ: plane_norm = rotated_direction(rotation^, Vector3{1, 0, 0});
                    case .MOVE_ZX: plane_norm = rotated_direction(rotation^, Vector3{0, 1, 0});
                    case: panic(tprint(move_type)); // note(josh): this was a return
                }

                diff := mouse_world - origin;
                prod := dot(diff, plane_norm);
                prod2 := dot(mouse_direction, plane_norm);
                prod3 := prod / prod2;
                intersect := mouse_world - mouse_direction * prod3;

                if !was_active {
                    last_point = intersect;
                }

                full_delta_move := intersect - last_point;
                delta_move: Vector3;

                #partial
                switch move_type {
                    case .MOVE_X: {
                        delta_move.x = dot(full_delta_move, rotated_direction(rotation^, direction_unary[0]));
                        break;
                    }
                    case .MOVE_Y: {
                        delta_move.y = dot(full_delta_move, rotated_direction(rotation^, direction_unary[1]));
                        break;
                    }
                    case .MOVE_Z: {
                        delta_move.z = dot(full_delta_move, rotated_direction(rotation^, direction_unary[2]));
                        break;
                    }
                    case .MOVE_YZ: {
                        delta_move.y = dot(full_delta_move, rotated_direction(rotation^, direction_unary[1]));
                        delta_move.z = dot(full_delta_move, rotated_direction(rotation^, direction_unary[2]));
                        break;
                    }
                    case .MOVE_ZX: {
                        delta_move.x = dot(full_delta_move, rotated_direction(rotation^, direction_unary[0]));
                        delta_move.z = dot(full_delta_move, rotated_direction(rotation^, direction_unary[2]));
                        break;
                    }
                    case .MOVE_XY: {
                        delta_move.x = dot(full_delta_move, rotated_direction(rotation^, direction_unary[0]));
                        delta_move.y = dot(full_delta_move, rotated_direction(rotation^, direction_unary[1]));
                        break;
                    }
                    case: {
                        delta_move = full_delta_move;
                    }
                }

                position^ += rotated_direction(rotation^, delta_move);
                last_point = intersect;
            }

            break;
        }
        case .Rotate: {
            closest_plane_distance := max(f32);
            closest_index := -1;
            for i in 0..2 {
                dir := rotated_direction(rotation^, direction_unary[i]);
                intersect_point, ok := coll.plane_intersect(position^, dir, g_editor_camera.position, mouse_direction);
                if ok {
                    dist_from_position := length(position^ - intersect_point);
                    // todo(josh): I don't think we should need a `size*NUM` here. `size` should be the radius of the rotation gizmo I think?
                    if dist_from_position < size*1.1 && dist_from_position > size*0.9 {
                        dist_to_camera := length(g_editor_camera.position - intersect_point);
                        if dist_to_camera < closest_plane_distance {
                            closest_plane_distance = dist_to_camera;
                            closest_index = i;
                        }
                    }
                }
            }

            if closest_index >= 0 {
                hovered_type = .ROTATE_X + Move_Type(closest_index);
                if wb.get_global_input_down(.Mouse_Left, true) {
                    mouse_pixel_position_on_rotate_clicked = g_game_view_mouse_pos;
                    rotation_on_rotate_clicked = rotation^;
                    move_type = hovered_type;
                }
            }



            if move_type != .NONE {
                sensitivity : f32 = 0.01;
                if wb.get_input(.Alt) do sensitivity *= 0.5;
                else if wb.get_input(.Shift) do sensitivity *= 2;
                rads := (g_game_view_mouse_pos.x - mouse_pixel_position_on_rotate_clicked.x) * sensitivity;

                dir_idx := -1;
                #partial
                switch move_type {
                    case .ROTATE_X: dir_idx = 0;
                    case .ROTATE_Y: dir_idx = 1;
                    case .ROTATE_Z: dir_idx = 2;
                }
                rot := Quaternion(1) * angle_axis(rads, rotated_direction(rotation_on_rotate_clicked, direction_unary[dir_idx]));
                rotation^ = rot * rotation_on_rotate_clicked;
            }

            break;
        }
        case .Scale: {
            was_active := move_type != .NONE;

            if move_type == .NONE {
                current_closest := max(f32);
                for i in 0..2 {
                    center_on_screen := wb.world_to_unit(camera, origin);
                    tip_on_screen := wb.world_to_unit(camera, origin + rotated_direction(rotation^, direction_unary[i]) * size);

                    p := coll.closest_point_on_line(to_vec3(unit_mouse_pos), center_on_screen, tip_on_screen);
                    dist := length(p - to_vec3(unit_mouse_pos));
                    if dist < size * 0.005 && dist < current_closest {
                        current_closest = dist;
                        hovered_type = Move_Type.SCALE_X + Move_Type(i);
                        if wb.get_global_input_down(.Mouse_Left, true) {
                            gizmo_state.scale_on_scale_clicked = scale^;
                            move_type = hovered_type;
                        }
                    }
                }
            }

            if move_type != .NONE {
                plane_norm: Vector3;
                #partial
                switch move_type {
                    case .SCALE_X:  plane_norm = rotated_direction(rotation^, Vector3{0, 0, 1});
                    case .SCALE_Y:  plane_norm = rotated_direction(rotation^, Vector3{0, 0, 1});
                    case .SCALE_Z:  plane_norm = rotated_direction(rotation^, Vector3{1, 0, 0});
                    case: panic(tprint(move_type)); // note(josh): this was a return
                }

                diff := mouse_world - origin;
                prod := dot(diff, plane_norm);
                prod2 := dot(mouse_direction, plane_norm);
                prod3 := prod / prod2;
                intersect := mouse_world - mouse_direction * prod3;

                if !was_active {
                    last_point = intersect;
                }

                full_delta_move := intersect - last_point;
                delta_move: Vector3;

                #partial
                switch move_type {
                    case .SCALE_X: delta_move.x = dot(full_delta_move, rotated_direction(rotation^, direction_unary[0]));
                    case .SCALE_Y: delta_move.y = dot(full_delta_move, rotated_direction(rotation^, direction_unary[1]));
                    case .SCALE_Z: delta_move.z = dot(full_delta_move, rotated_direction(rotation^, direction_unary[2]));
                    case: delta_move = full_delta_move;
                }

                scale^ += rotated_direction(rotation^, delta_move);
                last_point = intersect;
            }
        }
    }

    is_manipulating = move_type != .NONE;
    append(&im_gizmos, IM_Gizmo{position^, scale^, rotation^, gizmo_state^});

    if was_move_type != .NONE && move_type == .NONE {
        switch was_move_type {
            case .NONE: unreachable();
            case .MOVE_X, .MOVE_Y, .MOVE_Z, .MOVE_YZ, .MOVE_ZX, .MOVE_XY: return Gizmo_Move{gizmo_state.position_on_move_clicked, position^};
            case .ROTATE_X, .ROTATE_Y, .ROTATE_Z:                         return Gizmo_Rotate{gizmo_state.rotation_on_rotate_clicked, rotation^};
            case .SCALE_X, .SCALE_Y, .SCALE_Z:                            return Gizmo_Scale{};
        }
    }
    else {
        return nil;
    }
    unreachable();
}

rotated_direction :: proc(entity_rotation: Quaternion, direction: Vector3) -> Vector3 {
    if manipulation_mode == .World {
        return direction;
    }
    assert(manipulation_mode == .Local);
    return quat_mul_vec3(entity_rotation, direction);
}

IM_Gizmo :: struct {
    position: Vector3,
    scale: Vector3,
    rotation: Quaternion,
    state: Gizmo_State,
}

im_gizmos: [dynamic]IM_Gizmo;

gizmo_render :: proc(graph: ^wb.Render_Graph, im_context: ^wb.IM_Context) {
    {
        pass: wb.Render_Pass;
        pass.camera = &g_editor_camera;
        pass.color_buffers[0] = &gizmo_color_buffer;
        pass.depth_buffer = &gizmo_depth_buffer;
        wb.BEGIN_RENDER_PASS(&pass);

        for g in im_gizmos {
            g := g;

            using g;
            using g.state;

            rotation = quat_norm(rotation);
            if manipulation_mode == .World {
                rotation = Quaternion(1);
            }

            detail :: 10;
            #partial switch operation {
                case .Translate: {
                    verts: [detail*6]wb.Vertex;
                    head_verts: [detail*3]wb.Vertex;
                    quad_verts : [6]wb.Vertex;

                    for i in 0..2 {
                        dir   := direction_unary[i] * size;
                        dir_x := direction_unary[(i+1) % 3] * size;
                        dir_y := direction_unary[(i+2) % 3] * size;

                        color := direction_color[i];

                        if hovered_type == Move_Type.MOVE_X + Move_Type(i) || hovered_type == Move_Type.MOVE_YZ + Move_Type(i) {
                            color = selection_color;
                        }

                        RAD :: 0.03;

                        step := 0;
                        for i := 0; i < (detail * 6); i += 6 {
                            theta := TAU * f32(step) / f32(detail);
                            theta2 := TAU * f32(step+1) / f32(detail);

                            pt := dir_x * cos(theta) * RAD;
                            pt += dir_y * sin(theta) * RAD;
                            pt += dir * 0.9;
                            verts[i]   = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            pt  = dir_x * cos(theta2) * RAD;
                            pt += dir_y * sin(theta2) * RAD;
                            pt += dir * 0.9;
                            verts[i+1] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            pt  = dir_x * cos(theta) * RAD;
                            pt += dir_y * sin(theta) * RAD;
                            verts[i+2] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            verts[i+3] = verts[i+1];

                            pt  = dir_x * cos(theta2) * RAD;
                            pt += dir_y * sin(theta2) * RAD;
                            verts[i+4] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            verts[i+5] = verts[i+2];

                            step += 1;
                        }

                        rad2 : f32 = 0.1;
                        step = 0;
                        for i:= 0; i < int(detail*3); i+=3 {
                            theta := TAU * f32(step) / f32(detail);
                            theta2 := TAU * f32(step+1) / f32(detail);

                            pt := dir_x * cos(theta) * rad2;
                            pt += dir_y * sin(theta) * rad2;
                            pt += dir * 0.9;
                            head_verts[i]   = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            pt  = dir_x * cos(theta2) * rad2;
                            pt += dir_y * sin(theta2) * rad2;
                            pt += dir * 0.9;
                            head_verts[i+1] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            pt = dir * 1.1;
                            head_verts[i+2] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            step += 1;
                        }

                        quad_center := (dir_y + dir_x) * TRANSLATE_PLANE_OFFSET;
                        quad_pos: Vector3;
                        quad_pos = quad_center + ( dir_x + dir_y) * TRANSLATE_PLANE_SIZE; quad_verts[0] = wb.Vertex{Vector4{quad_pos.x, quad_pos.y, quad_pos.z, 1}, {}, color, {}, {}, {}, {}, {} };
                        quad_pos = quad_center + ( dir_x - dir_y) * TRANSLATE_PLANE_SIZE; quad_verts[1] = wb.Vertex{Vector4{quad_pos.x, quad_pos.y, quad_pos.z, 1}, {}, color, {}, {}, {}, {}, {} };
                        quad_pos = quad_center + (-dir_x - dir_y) * TRANSLATE_PLANE_SIZE; quad_verts[2] = wb.Vertex{Vector4{quad_pos.x, quad_pos.y, quad_pos.z, 1}, {}, color, {}, {}, {}, {}, {} };
                        quad_verts[3] = quad_verts[2];
                        quad_pos = quad_center + (-dir_x + dir_y) * TRANSLATE_PLANE_SIZE; quad_verts[4] = wb.Vertex{Vector4{quad_pos.x, quad_pos.y, quad_pos.z, 1}, {}, color, {}, {}, {}, {}, {} };
                        quad_verts[5] = quad_verts[0];

                        wb.update_mesh(&gizmo_mesh, 0, quad_verts[:], []u32{});
                        wb.draw_model(&gizmo_mesh, position, {1,1,1}, rotation, {}, {1, 1, 1, 1});

                        wb.update_mesh(&gizmo_mesh, 0, head_verts[:], []u32{});
                        wb.draw_model(&gizmo_mesh, position, {1,1,1}, rotation, {}, {1, 1, 1, 1});

                        wb.update_mesh(&gizmo_mesh, 0, verts[:], []u32{});
                        wb.draw_model(&gizmo_mesh, position, {1,1,1}, rotation, {}, {1, 1, 1, 1});
                    }
                    break;
                }
                case .Rotate: {
                    hoop_segments :: 52;
                    tube_segments :: 10;
                    tube_radius :f32= 0.02;

                    for direction in 0..2 {
                        dir_x := direction_unary[(direction+1) % 3] * size;
                        dir_y := direction_unary[(direction+2) % 3] * size;
                        dir_z := direction_unary[ direction       ] * size;
                        color := direction_color[ direction       ];

                        if hovered_type == Move_Type.ROTATE_X + Move_Type(direction) do color = selection_color;

                        verts: [hoop_segments * tube_segments * 6]wb.Vertex;
                        vi := 0;

                        start : f32 = 0;
                        end : f32 = hoop_segments;

                        start_angle :f32= 0;
                        if direction == 0 do start_angle = -PI / 5;
                        if direction == 1 do start_angle = -PI / 5;
                        if direction == 2 do start_angle = -PI / 2.4 + PI / 5;

                        offset_rot : f32 = -PI/4;

                        for i : f32 = start; i < end; i+=1 {
                            angle_a1 := start_angle + TAU * (i-1) / hoop_segments;
                            angle_a2 := start_angle + TAU * i / hoop_segments;

                            for j : f32 = 0; j < tube_segments; j += 1 {
                                angle_b1 := TAU * ((j-1) / tube_segments);
                                angle_b2 := TAU * (j / tube_segments);

                                make_point :: proc(input: Vector3, dir_x, dir_y, dir_z: Vector3) -> Vector3 {
                                    pt := dir_x * input.x;
                                    pt += dir_y * input.y;
                                    pt += dir_z * input.z;
                                    return pt;
                                }

                                // triangle 1
                                pt1 := make_point(Vector3 {
                                    (1 + tube_radius * cos(angle_b1)) * cos(angle_a1),
                                    (1 + tube_radius * cos(angle_b1)) * sin(angle_a1),
                                    tube_radius * sin(angle_b1)
                                }, dir_x, dir_y, dir_z);

                                pt2 := make_point(Vector3 {
                                    (1 + tube_radius * cos(angle_b2)) * cos(angle_a1),
                                    (1 + tube_radius * cos(angle_b2)) * sin(angle_a1),
                                    tube_radius * sin(angle_b2)
                                }, dir_x, dir_y, dir_z);

                                pt3 := make_point(Vector3 {
                                    (1 + tube_radius * cos(angle_b1)) * cos(angle_a2),
                                    (1 + tube_radius * cos(angle_b1)) * sin(angle_a2),
                                    tube_radius * sin(angle_b1)
                                }, dir_x, dir_y, dir_z);

                                // triangle 2
                                pt4 := make_point(Vector3 {
                                    (1 + tube_radius * cos(angle_b2)) * cos(angle_a2),
                                    (1 + tube_radius * cos(angle_b2)) * sin(angle_a2),
                                    tube_radius * sin(angle_b2)
                                }, dir_x, dir_y, dir_z);

                                pt5 := make_point(Vector3 {
                                    (1 + tube_radius * cos(angle_b1)) * cos(angle_a2),
                                    (1 + tube_radius * cos(angle_b1)) * sin(angle_a2),
                                    tube_radius * sin(angle_b1)
                                }, dir_x, dir_y, dir_z);

                                pt6 := make_point(Vector3 {
                                    (1 + tube_radius * cos(angle_b2)) * cos(angle_a1),
                                    (1 + tube_radius * cos(angle_b2)) * sin(angle_a1),
                                    tube_radius * sin(angle_b2)
                                }, dir_x, dir_y, dir_z);

                                verts[vi] = wb.Vertex { Vector4{pt1.x, pt1.y, pt1.z, 1}, {}, color, {}, {}, {}, {}, {} };
                                vi += 1;
                                verts[vi] = wb.Vertex { Vector4{pt2.x, pt2.y, pt2.z, 1}, {}, color, {}, {}, {}, {}, {} };
                                vi += 1;
                                verts[vi] = wb.Vertex { Vector4{pt3.x, pt3.y, pt3.z, 1}, {}, color, {}, {}, {}, {}, {} };
                                vi += 1;

                                verts[vi] = wb.Vertex { Vector4{pt4.x, pt4.y, pt4.z, 1}, {}, color, {}, {}, {}, {}, {} };
                                vi += 1;
                                verts[vi] = wb.Vertex { Vector4{pt5.x, pt5.y, pt5.z, 1}, {}, color, {}, {}, {}, {}, {} };
                                vi += 1;
                                verts[vi] = wb.Vertex { Vector4{pt6.x, pt6.y, pt6.z, 1}, {}, color, {}, {}, {}, {}, {} };
                                vi += 1;
                            }
                        }

                        wb.update_mesh(&gizmo_mesh, 0, verts[:], []u32{});
                        wb.draw_model(&gizmo_mesh, position, {1,1,1}, rotation, {}, {1, 1, 1, 1});
                    }

                    break;
                }
                case .Scale: {
                    verts: [detail*6]wb.Vertex;
                    head_verts: [detail*3]wb.Vertex;
                    quad_verts : [6]wb.Vertex;

                    for i in 0..2 {
                        dir   := direction_unary[i] * size;
                        dir_x := direction_unary[(i+1) % 3] * size;
                        dir_y := direction_unary[(i+2) % 3] * size;

                        color := direction_color[i];

                        if hovered_type == Move_Type.MOVE_X + Move_Type(i) || hovered_type == Move_Type.MOVE_YZ + Move_Type(i) {
                            color = selection_color;
                        }

                        RAD :: 0.03;

                        step := 0;
                        for i := 0; i < (detail * 6); i += 6 {
                            theta := TAU * f32(step) / f32(detail);
                            theta2 := TAU * f32(step+1) / f32(detail);

                            pt := dir_x * cos(theta) * RAD;
                            pt += dir_y * sin(theta) * RAD;
                            pt += dir * 0.9;
                            verts[i]   = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            pt  = dir_x * cos(theta2) * RAD;
                            pt += dir_y * sin(theta2) * RAD;
                            pt += dir * 0.9;
                            verts[i+1] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            pt  = dir_x * cos(theta) * RAD;
                            pt += dir_y * sin(theta) * RAD;
                            verts[i+2] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            verts[i+3] = verts[i+1];

                            pt  = dir_x * cos(theta2) * RAD;
                            pt += dir_y * sin(theta2) * RAD;
                            verts[i+4] = wb.Vertex{ Vector4{pt.x, pt.y, pt.z, 1}, {}, color, {}, {}, {}, {}, {} };

                            verts[i+5] = verts[i+2];

                            step += 1;
                        }

                        wb.update_mesh(&gizmo_mesh, 0, verts[:], []u32{});
                        wb.draw_model(&gizmo_mesh, position, {1,1,1}, rotation, {}, {1, 1, 1, 1});
                    }
                }
            }
        }

        // TODO manipulate this
        // wb.draw_model(wb.g_models["cube_model"], game.g_game_camera.position, {1,1,1}, game.g_game_camera.orientation, wb.g_materials["simple_rgba_mtl"], {1, 0, 0, 1});
    }
}

Manipulation_Mode :: enum {
    World,
    Local,
}

Operation :: enum {
    Translate,
    Rotate,
    Scale,
    None,
}

Move_Type :: enum {
    NONE,

    MOVE_X, MOVE_BEGIN = MOVE_X,
    MOVE_Y,
    MOVE_Z,
    MOVE_YZ,
    MOVE_ZX,
    MOVE_XY, MOVE_END = MOVE_XY,

    ROTATE_X, ROTATE_BEGIN = ROTATE_X,
    ROTATE_Y,
    ROTATE_Z, ROTATE_END = ROTATE_Z,

    SCALE_X, SCALE_BEGIN = SCALE_X,
    SCALE_Y,
    SCALE_Z, SCALE_END = SCALE_Z,
}