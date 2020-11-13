package shared

import "shared:wb"

WINDOW_SIZE_X :: 2560;
WINDOW_SIZE_Y :: 1440;

NUM_SHADOW_MAPS :: 3;

Current_Game_State := Game_State.Initializing;

g_collision_scene: wb.Collision_Scene;

Game_State :: enum {
    Initializing,
    
    Login_Screen,
    Character_Select,
    In_Game,
}

Render_Graph_Context :: struct {
    target_camera: ^wb.Camera,
    screen_im_context: ^wb.IM_Context,
    world_im_context: ^wb.IM_Context,
    editor_im_context: ^wb.IM_Context,
    edit_mode: bool,
}

Draw_Command :: struct {
    model:             ^wb.Model,
    position:          Vector3,
    scale:             Vector3,
    orientation:       Quaternion,
    material_override: ^wb.Material,
    color:             Vector4,
    draws_shadow:      bool,
    entity:            rawptr,
    animator:          rawptr,
}

Texture_Slot :: enum {
    Shadow_Map1 = len(wb.Builtin_Texture),
    Shadow_Map2,
    Shadow_Map3,
    Shadow_Map4,
}

CBuffer_Slot :: enum {
    Lighting = len(wb.Builtin_CBuffer),
}

Vector3i :: distinct [3]i32;
Vector4i :: distinct [4]i32;

Vector2 :: wb.Vector2;
Vector3 :: wb.Vector3;
Vector4 :: wb.Vector4;
Quaternion :: wb.Quaternion;
Matrix4 :: wb.Matrix4;