package gizmo

using import "core:math"
using import "core:fmt"

using import "shared:workbench/basic"
using import "shared:workbench/types"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"

import wb_plat "shared:workbench/platform"
import wb_col  "shared:workbench/collision"
import wb_math "shared:workbench/math"
import wb_gpu  "shared:workbench/gpu"
import wb      "shared:workbench"
import         "shared:workbench/external/imgui"
import         "shared:workbench/external/gl"

direction_unary := [3]Vec3{ Vec3{1,0,0}, Vec3{0,1,0}, Vec3{0,0,1}  };
direction_color := [3]Colorf{ Colorf{1,0,0,1}, Colorf{0,1,0,1}, Colorf{0,0,1,1}  };
selection_color := Colorf{1,1,0.1,1};

operation : Operation;
active_entity: Entity;

size: f32 = 0;
is_hovering:= [3]bool{};
is_active := false;
hovering := -1;
last_point := Vec3{};
move_type := MoveType.NONE;

should_reset := true;

gizmo_mesh : wb.Model;

rad : f32 = 0.05;

init :: proc() {
    wb.add_mesh_to_model(&gizmo_mesh, []wb.Vertex3D{}, []u32{});
}

reset :: proc() {
    should_reset = true;
    is_active = false;
    hovering = -1;
    move_type = .NONE;
}

manipulate :: proc(entity: Entity, do_move: bool) {
    
    active_entity = entity;
    transform, ok := get_component(active_entity, Transform);
    
    camera_pos := wb.wb_camera.position;
    origin := transform.position;
    
    size = length(transform.position - camera_pos) * 0.15;
    is_hovering[0] = false;
    is_hovering[1] = false;
    is_hovering[2] = false;
    
    
    switch operation
    {
        case Operation.Translate: {
            
            mouse_world := wb.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
            mouse_direction := wb.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
            
            intersect: Vec3;
            
            if !is_active { // get new axis
                outer: for i in 0..2 {
                    casted : f32 = 0;
                    step := 0;
                    for casted < size {
                        info, hit := 
                            wb_col.cast_line_box(wb.wb_camera.position, 
                                                 mouse_direction * 100, origin + direction_unary[i]* rad + (direction_unary[i] * rad*f32(step)), 
                                                 Vec3{rad,rad,rad} * 2);
                        
                        if hit {
                            hovering = i;
                            move_type = MoveType(i + 1);
                            intersect = info.point0;
                            break outer;
                        }
                        
                        casted += rad;
                        step += 1;
                    }
                }
                
                if move_type == .NONE {
                    for i in  0..2 {
                        dir := direction_unary[i] * size;
                        dir_x := direction_unary[(i+1) %3] * size;
                        dir_y := direction_unary[(i+2) %3] * size;
                        
                        quad_size: f32 = 0.5;
                        quad_origin := origin + (dir_y + dir_x) * 0.2;
                        
                        plane_norm := direction_unary[i];
                        
                        diff := mouse_world - quad_origin;
                        prod := dot(diff, plane_norm);
                        prod2 := dot(mouse_direction, plane_norm);
                        prod3 := prod / prod2;
                        q_i := mouse_world - mouse_direction * prod3;
                        intersect = q_i;
                        
                        using wb_math;
                        
                        q_p1 := quad_origin;
                        q_p2 := quad_origin + (dir_y + dir_x)*quad_size;
                        min := Vec3{ minv(q_p1.x, q_p2.x), minv(q_p1.y, q_p2.y), minv(q_p1.z, q_p2.z) };
                        max := Vec3{ maxv(q_p1.x, q_p2.x), maxv(q_p1.y, q_p2.y), maxv(q_p1.z, q_p2.z) };
                        
                        contains := 
                            q_i.x >= min.x && 
                            q_i.x <= max.x && 
                            q_i.y >= min.y && 
                            q_i.y <= max.y &&
                            q_i.z >= min.z &&
                            q_i.z <= max.z;
                        
                        if contains {
                            hovering = i;
                            move_type = MoveType.MOVE_YZ + MoveType(i);
                            break;
                        }
                    }
                }
                
            } else {
                plane_norm := Vec3{0,1,0};
                if move_type == .MOVE_Y {
                    plane_norm = wb_math.quaternion_back(wb.wb_camera.rotation);
                    plane_norm.y = 0;
                }
                
                if move_type == .MOVE_XY || move_type == .MOVE_YZ {
                    plane_norm = direction_unary[hovering];
                }
                
                diff := mouse_world - origin;
                prod := dot(diff, plane_norm);
                prod2 := dot(mouse_direction, plane_norm);
                prod3 := prod / prod2;
                intersect = mouse_world - mouse_direction * prod3;
            }
            
            if move_type != .NONE {
                is_hovering[hovering] = true;
                is_active = true;
                
                if should_reset {
                    last_point = intersect;
                }
                
                if do_move {
                    delta_move := intersect - last_point;
                    
                    switch move_type
                    {
                        case .MOVE_X: {
                            delta_move = Vec3{
                                dot(delta_move, direction_unary[0]), 
                                0, 
                                0};
                            break;
                        }
                        case .MOVE_Y: {
                            delta_move = Vec3{
                                0, 
                                dot(delta_move, direction_unary[1]), 
                                0};
                            break;
                        }
                        case .MOVE_Z: {
                            delta_move = Vec3{
                                0, 
                                0, 
                                dot(delta_move, direction_unary[2])};
                            break;
                        }
                        case .MOVE_YZ: {
                            delta_move = Vec3 { 
                                0,
                                dot(delta_move, direction_unary[1]), 
                                dot(delta_move, direction_unary[2]) };
                            break;
                        }
                        case .MOVE_ZX: {
                            delta_move = Vec3 { 
                                dot(delta_move, direction_unary[0]), 
                                0,
                                dot(delta_move, direction_unary[2]) };
                            break;
                        }
                        case . MOVE_XY: {
                            delta_move = Vec3 { 
                                dot(delta_move, direction_unary[0]), 
                                dot(delta_move, direction_unary[1]),
                                0};
                            break;
                        }
                    }
                    
                    transform.position += delta_move;
                    last_point = intersect;
                }
            }
            
            break;
        }
        case Operation.Rotate: {
            break;
        }
        case Operation.Scale: {
            break;
        }
    }
    
    should_reset = false;
}

render :: proc() {
    
    if should_reset do return;
    
    transform, ok := get_component(active_entity, Transform);
    origin := transform.position;
    
    switch operation
    {
        case Operation.Translate: {
            
            wb_gpu.use_program(wb.shader_texture_lit);
            detail :: 30;
            
            verts: [detail*4]wb.Vertex3D;
            head_verts: [detail*3]wb.Vertex3D;
            quad_verts : [4]wb.Vertex3D;
            
            for i in 0..2 {
                dir := direction_unary[i] * size;
                dir_x := direction_unary[(i+1) %3] * size;
                dir_y := direction_unary[(i+2) %3] * size;
                
                color := direction_color[i];
                
                if is_hovering[i] {
                    color = selection_color;
                }
                
                step := 0;
                for i := 0; i < int(detail)*4; i+=4 {
                    
                    theta := TAU * f32(step) / f32(detail);
                    theta2 := TAU * f32(step+1) / f32(detail);
                    
                    pt := dir_x * cos(theta) * rad;
                    pt += dir_y * sin(theta) * rad;
                    pt += dir;
                    pt += origin;
                    verts[i] = wb.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta2) * rad;
                    pt  += dir_y *sin(theta2) * rad;
                    pt += dir;
                    pt += origin;
                    verts[i+1] = wb.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta) * rad;
                    pt += dir_y *sin(theta) * rad;
                    pt += origin;
                    verts[i+2] = wb.Vertex3D{ 
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta2) * rad;
                    pt += dir_y *sin(theta2) * rad;
                    pt += origin;
                    verts[i+3] = wb.Vertex3D{ 
                        pt, {}, color, {}
                    };
                    
                    step += 1;
                }
                
                rad2 : f32 = 0.1;
                step = 0;
                for i:= 0; i < int(detail*3); i+=3 {
                    theta := TAU * f32(step) / f32(detail);
                    theta2 := TAU * f32(step+1) / f32(detail);
                    
                    pt := dir_x * cos(theta) * rad2;
                    pt += dir_y * sin(theta) * rad2;
                    pt += dir;
                    pt += origin;
                    head_verts[i] = wb.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta2) * rad2;
                    pt  += dir_y *sin(theta2) * rad2;
                    pt += dir;
                    pt += origin;
                    head_verts[i+1] = wb.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = origin + (dir * 1.25);
                    head_verts[i+2] = wb.Vertex3D{ 
                        pt, {}, color, {}
                    };
                    
                    step += 1;
                }
                
                quad_size: f32 = 0.5;
                quad_origin := origin + (dir_y + dir_x) * 0.2;
                quad_verts[0] = wb.Vertex3D{quad_origin, {}, color, {} };
                quad_verts[1] = wb.Vertex3D{quad_origin + dir_y*quad_size, {}, color, {} };
                quad_verts[2] = wb.Vertex3D{quad_origin + (dir_y + dir_x)*quad_size, {}, color, {} };
                quad_verts[3] = wb.Vertex3D{quad_origin + dir_x*quad_size, {}, color, {} };
                
                prev_draw_mode := wb.wb_camera.draw_mode;
                wb.wb_camera.draw_mode = wb_gpu.Draw_Mode.Triangle_Fan;
                
                wb.update_mesh(&gizmo_mesh, 0, quad_verts[:], []u32{});
                wb.draw_model(gizmo_mesh, {}, {1,1,1}, {0,0,0,1}, {}, color, false);
                
                wb.update_mesh(&gizmo_mesh, 0, head_verts[:], []u32{});
                wb.draw_model(gizmo_mesh, {}, {1,1,1}, {0,0,0,1}, {}, color, false);
                
                wb.update_mesh(&gizmo_mesh, 0, verts[:], []u32{});
                wb.draw_model(gizmo_mesh, {}, {1,1,1}, {0,0,0,1}, {}, color, false);
                
                wb.wb_camera.draw_mode = prev_draw_mode;
            }
            break;
        }
        case Operation.Rotate: {
            break;
        }
        case Operation.Scale: {
            break;
        }
    }
}

Operation :: enum {
    Translate,
    Rotate,
    Scale,
}

Mode :: enum {
    Local, World
}

MoveType :: enum {
    NONE,
    
    MOVE_X,
    MOVE_Y,
    MOVE_Z,
    MOVE_YZ,
    MOVE_ZX,
    MOVE_XY,
    
    ROTATE_X,
    ROTATE_Y,
    ROTATE_Z,
}