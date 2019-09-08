package gizmo

using import "core:math"
using import "core:fmt"

using import "shared:workbench/basic"
using import "shared:workbench/types"
using import "shared:workbench/logging"
using import "shared:workbench/ecs"

import wb_plat "shared:workbench/platform"
import wb_col  "shared:workbench/collision"
import wb_gpu  "shared:workbench/gpu"
import wb_math "shared:workbench/math"
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

should_reset := true;

gizmo_mesh : wb_gpu.Model;

rad : f32 = 0.05;

init :: proc() {
    wb_gpu.add_mesh_to_model(&gizmo_mesh, "translation", []wb_gpu.Vertex3D{}, []u32{});
}

reset :: proc() {
    should_reset = true;
    is_active = false;
    hovering = -1;
}

manipulate :: proc(entity: Entity, do_move: bool) {
    
    transform, ok := get_component(entity, Transform);
    camera_pos := wb.wb_camera.position;
    origin := transform.position;
    
    active_entity = entity;
    size = length(transform.position - camera_pos) * 0.15;
    is_hovering[0] = false;
    is_hovering[1] = false;
    is_hovering[2] = false;
    
    new_pos := Vec3{};
    
    switch operation
    {
        case Operation.Translate: {
            
            mouse_world := wb_gpu.get_mouse_world_position(&wb.wb_camera, wb_plat.mouse_unit_position);
            mouse_direction := wb_gpu.get_mouse_direction_from_camera(&wb.wb_camera, wb_plat.mouse_unit_position);
            
            intersect: Vec3;
            
            if !is_active || hovering == 1 { // get new axis, need to rotate plane for y move to guna skip that for now
                outer: for i in 0..2 {
                    casted : f32 = 0;
                    step := 0;
                    for casted < size {
                        info, hit := 
                            wb_col.cast_line_box(wb.wb_camera.position, 
                                                 mouse_direction * 100, origin + direction_unary[i]* rad + (direction_unary[i] * rad*f32(step)), 
                                                 Vec3{rad,rad,rad} * 2);
                        intersect = info.point0;
                        
                        if hit {
                            hovering = i;
                            break outer;
                        }
                        
                        casted += rad;
                        step += 1;
                    }
                }
            } else {
                
                plane_pos_mod := Vec3{0,5000,0};
                // TODO y axis
                
                if transform.position.y > wb.wb_camera.position.y do plane_pos_mod *= -1;
                
                info, hit := wb_col.cast_line_box(wb.wb_camera.position, 
                                                  mouse_direction*10000,
                                                  last_point - plane_pos_mod,
                                                  Vec3{10000, 10000, 10000});
                intersect = info.point0;
            }
            
            if hovering >= 0 {
                
                is_hovering[hovering] = true;
                is_active = true;
                
                if should_reset {
                    last_point = intersect;
                }
                
                if do_move {
                    delta_move := intersect - last_point;
                    
                    switch hovering
                    {
                        case 0: {
                            delta_move = Vec3{ dot(delta_move, direction_unary[0]), 0, 0  };
                            break;
                        }
                        case 1: {
                            delta_move = Vec3{ 0, dot(delta_move, direction_unary[1]), 0 };
                            break;
                        }
                        case 2: {
                            delta_move = Vec3{ 0, 0, dot(delta_move, direction_unary[2]) };
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
            
            wb_gpu.use_program(wb.shader_rgba_3d);
            detail :: 30;
            
            verts: [detail*4]wb_gpu.Vertex3D;
            head_verts: [detail*3]wb_gpu.Vertex3D;
            
            size := size;
            
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
                    verts[i] = wb_gpu.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta2) * rad;
                    pt  += dir_y *sin(theta2) * rad;
                    pt += dir;
                    pt += origin;
                    verts[i+1] = wb_gpu.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta) * rad;
                    pt += dir_y *sin(theta) * rad;
                    pt += origin;
                    verts[i+2] = wb_gpu.Vertex3D{ 
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta2) * rad;
                    pt += dir_y *sin(theta2) * rad;
                    pt += origin;
                    verts[i+3] = wb_gpu.Vertex3D{ 
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
                    head_verts[i] = wb_gpu.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = dir_x * cos(theta2) * rad2;
                    pt  += dir_y *sin(theta2) * rad2;
                    pt += dir;
                    pt += origin;
                    head_verts[i+1] = wb_gpu.Vertex3D {
                        pt, {}, color, {}
                    };
                    
                    pt = origin + (dir * 1.25);
                    head_verts[i+2] = wb_gpu.Vertex3D{ 
                        pt, {}, color, {}
                    };
                    
                    step += 1;
                }
                
                prev_draw_mode := wb.wb_camera.draw_mode;
                wb.wb_camera.draw_mode = wb_gpu.Draw_Mode.Triangle_Fan;
                
                wb_gpu.update_mesh(&gizmo_mesh, "translation", head_verts[:], []u32{});
                wb_gpu.draw_model(gizmo_mesh, {}, {1,1,1}, {0,0,0,1}, {}, color, false);
                
                wb_gpu.update_mesh(&gizmo_mesh, "translation", verts[:], []u32{});
                wb_gpu.draw_model(gizmo_mesh, {}, {1,1,1}, {0,0,0,1}, {}, color, false);
                
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

Collision_Box :: struct {
    origin: Vec3,
    direction: Vec3,
    width: f32,
    length: f32,
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
    MOVE_SCREEN,
    ROTATE_X,
    ROTATE_Y,
    ROTATE_Z,
    ROTATE_SCREEN,
    SCALE_X,
    SCALE_Y,
    SCALE_Z,
    SCALE_XYZ
}