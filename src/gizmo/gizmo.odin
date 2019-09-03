package gizmo

using import "core:math"
using import "core:fmt"

using import "shared:workbench/basic"
using import "shared:workbench/types"

import wb_plat "shared:workbench/platform"
import wb_gpu  "shared:workbench/gpu"
import wb_math  "shared:workbench/math"
import wb      "shared:workbench"
import         "shared:workbench/external/imgui"

plane_color := [3]int{ 0x610000AA, 0x6100AA00, 0x61AA0000 };
selection_color := 0x8A1080FF;
inactive_color := 0x99999999;
direction_color := [3]int{ 0xFF0000AA, 0xFF00AA00, 0xFFAA0000 };

current_context := Context{};

world_to_pos :: proc(worldPos: Vec3, mat: Mat4) -> imgui.Vec2 {
    trans: Vec4;
    trans.x = trans.x * mat[0][0] + trans.y * mat[1][0] + trans.z * mat[2][0] + mat[3][0];
    trans.y = trans.x * mat[0][1] + trans.y * mat[1][1] + trans.z * mat[2][1] + mat[3][1];
    trans.z = trans.x * mat[0][2] + trans.y * mat[1][2] + trans.z * mat[2][2] + mat[3][2];
    trans.w = trans.x * mat[0][3] + trans.y * mat[1][3] + trans.z * mat[2][3] + mat[3][3];
    
    trans *= 0.5 / trans.w;
    trans += Vec4{0.5, 0.5, 0, 0};
    trans.y = 1 - trans.y;
    
    
    return imgui.Vec2{};
}

transform_point :: proc(pt : Vec4, matrix : Mat4) -> Vec4 {
    out := pt;
    
    out.x = pt.x * matrix[0][0] + pt.y * matrix[1][0] + pt.z * matrix[2][0];
    out.y = pt.x * matrix[0][1] + pt.y * matrix[1][1] + pt.z * matrix[2][1];
    out.z = pt.x * matrix[0][2] + pt.y * matrix[1][2] + pt.z * matrix[2][2];
    out.w = pt.x * matrix[0][3] + pt.y * matrix[1][3] + pt.z * matrix[2][3];
    
    return out;
}

direction_unary := [3]Vec3{Vec3{1,0,0}, Vec3{0,1,0}, Vec3{0,0,1}};

manipulate :: proc(view, projection : Mat4, o: Operation, m: Mode, entity: Mat4) -> Mat4 {
    
    draw_lists := imgui.get_window_draw_list();
    entity_pos := Vec3{ entity[3][0], entity[3][1], entity[3][2] };
    
    current_context.vp = mul(view, projection);
    current_context.mvp = mul(current_context.vp , entity);
    current_context.display_ratio = wb.wb_camera.pixel_width / wb.wb_camera.pixel_height;
    
    current_context.screen_factor = 1;
    
    switch o
    {
        case Operation.Translate: {
            origin := world_to_pos(entity_pos, view);
            colors := compute_colors(MoveType.NONE, Operation.Translate);
            
            for i in 0..3 {
                dir_axis, dir_plane_x, dir_plane_y :=  compute_tripod_axis_and_vis(i);
                
                if current_context.below_axis_limit[i] {
                    base_s_space := world_to_pos(dir_axis * .1 * current_context.screen_factor, current_context.mvp);
                    
                    world_dir_s_space := world_to_pos(dir_axis * current_context.screen_factor, current_context.mvp);
                    
                    imgui.draw_list_add_line(draw_lists, base_s_space, world_dir_s_space, u32(colors[i+1]), 3);
                }
                
                if current_context.below_plane_limit[i] {
                    
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
    
    return Mat4{};
}

compute_colors :: proc(mt : MoveType, op : Operation) -> [7]int {
    colors : [7]int = {};
    
    switch op {
        case Operation.Translate: {
            if mt == MoveType.MOVE_SCREEN do colors[0] = selection_color;
            else do colors[0] = 0xFFFFFFFF;
            
            for i in 0..3 {
                if mt == MoveType.MOVE_X do colors[i+1] = selection_color;
                else do colors[i+1] = direction_color[i];
                
                if mt == MoveType.MOVE_YZ do colors[i+4] = selection_color;
                else do colors[i+4] = plane_color[i];
                
                if mt == MoveType.MOVE_SCREEN do colors[i+4] = selection_color;
                else do colors[i+4] = colors[i+4];
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
    
    return colors;
}

compute_tripod_axis_and_vis :: proc(i: int) -> (Vec3, Vec3, Vec3) {
    dir_axis := direction_unary[i];
    dir_plane_x := direction_unary[(i+1) % 3];
    dir_plane_y := direction_unary[(i+2) % 3];
    
    below_axis_limit := false;
    below_plane_limit := false;
    
    if current_context.is_using {
        dir_axis *= current_context.axis_factor[i];
        dir_plane_x *= current_context.axis_factor[(i+1) % 3];
        dir_plane_y *= current_context.axis_factor[(i+2) % 3];
    }
    else {
        len_dir := get_segment_length_clip_space(Vec3{0,0,0}, dir_axis);
        len_dir_minus := get_segment_length_clip_space(Vec3{0,0,0}, -dir_axis);
        
        len_dir_plane_x := get_segment_length_clip_space(Vec3{0,0,0}, dir_plane_x);
        len_dir_plane_x_minus := get_segment_length_clip_space(Vec3{0,0,0}, -dir_plane_x);
        
        len_dir_plane_y := get_segment_length_clip_space(Vec3{0,0,0}, dir_plane_x);
        len_dir_plane_y_minus := get_segment_length_clip_space(Vec3{0,0,0}, -dir_plane_y);
        
        mul_axis : f32 = 1;
        if len_dir < len_dir_minus && abs(len_dir-len_dir_minus) > F32_EPSILON {
            mul_axis = -1;
        }
        dir_axis *= mul_axis;
        
        mul_axis_x : f32 = 1;
        if len_dir_plane_x < len_dir_plane_x_minus && abs(len_dir_plane_x-len_dir_plane_x_minus) > F32_EPSILON {
            mul_axis_x = -1;
        }
        dir_plane_x *= mul_axis_x;
        
        mul_axis_y : f32 = 1;
        if len_dir_plane_y < len_dir_plane_y_minus && abs(len_dir_plane_y-len_dir_plane_y_minus) > F32_EPSILON { 
            mul_axis_y = -1;
        }
        dir_plane_y *= mul_axis_y;
        
        axis_length_clip_space := get_segment_length_clip_space(Vec3{0,0,0}, dir_axis * current_context.screen_factor);
        para_surf := get_parallelogram(Vec3{0,0,0}, dir_plane_x * current_context.screen_factor, dir_plane_y * current_context.screen_factor);
        below_plane_limit = para_surf > 0.0025;
        below_axis_limit = axis_length_clip_space > 0.02;
        
        current_context.axis_factor[i] = mul_axis;
        current_context.axis_factor[(i+1) % 3] = mul_axis_x;
        current_context.axis_factor[(i+2) % 3] = mul_axis_y;
        current_context.below_axis_limit[i] = below_axis_limit;
        current_context.below_plane_limit[i] = below_plane_limit;
    }
    
    return dir_axis, dir_plane_x, dir_plane_y;
}

get_segment_length_clip_space :: proc(start, end : Vec3) -> f32 {
    start_of_segment := transform_point(make_vec4(start), current_context.mvp);
    
    if abs(start_of_segment.w) > F32_EPSILON do start_of_segment *= 1 / start_of_segment.w;
    
    end_of_segment := transform_point(make_vec4(end), current_context.mvp);
    
    if abs(end_of_segment.w) > F32_EPSILON do end_of_segment *= 1 / end_of_segment.w;
    
    clip_space_axis := end_of_segment - start_of_segment;
    clip_space_axis.y /= current_context.display_ratio;
    
    return sqrt(clip_space_axis.x * clip_space_axis.x + clip_space_axis.y * clip_space_axis.y);
}

get_parallelogram :: proc(pt1, pt2, pt3: Vec3) -> f32 {
    pts := [3]Vec4{make_vec4(pt1), make_vec4(pt2), make_vec4(pt3)};
    for i in 0..3 {
        pts[i] = transform_point(pts[i], current_context.mvp);
        if abs(pts[i].w) > F32_EPSILON do pts[i] *= 1/pts[i].w;
    }
    
    seg_a := pts[1] - pts[0];
    seg_b := pts[2] - pts[0];
    seg_a.y /= current_context.display_ratio;
    seg_b.y /= current_context.display_ratio;
    
    seg_a_ortho := Vec4{-seg_a.y, seg_a.x, 0, 0};
    seg_a_ortho = norm(seg_a_ortho);
    
    dt := dot(seg_a_ortho, seg_b);
    surface := sqrt(seg_a.x*seg_a.x + seg_a.y * seg_a.y) * abs(dt);
    
    return surface;
}

make_vec4 :: proc(input: Vec3) -> Vec4 {
    return Vec4{input.x, input.y, input.z, 0};
}

Context :: struct {
    is_using : bool,
    
    below_axis_limit : [3]bool,
    below_plane_limit : [3]bool,
    axis_factor : [3]f32,
    
    vp : Mat4,
    mvp : Mat4,
    
    display_ratio : f32,
    screen_factor : f32,
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