package editor

import "shared:wb/logging"
import "core:fmt"
import "core:strings"
import "core:mem"
import "core:runtime"
import "core:math"
import la "core:math/linalg"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/imgui"

import "../configs"
import "../entity"
import "../shared"

enabled := false;

g_editor_camera: wb.Camera;

entity_id_color_buffer: wb.Texture;
entity_id_depth_buffer: wb.Texture;
entity_id_buffer_cpu_copy: wb.Texture;

hovered_entity_index: int;

gizmo_state: Gizmo_State;

init :: proc() {
    wb.init_camera(&g_editor_camera);
    g_editor_camera.is_perspective = true;
    g_editor_camera.position = Vector3{0, 0, -15};
    g_editor_camera.orientation = wb.direction_to_quaternion(wb.norm(-g_editor_camera.position));

    entity_id_color_buffer, entity_id_depth_buffer = wb.create_color_and_depth_buffers(wb.main_window.width_int, wb.main_window.height_int, .R32_INT);

    texture_desc := entity_id_color_buffer.description;
    texture_desc.render_target = false;
    texture_desc.is_cpu_read_target = true;
    entity_id_buffer_cpu_copy = wb.create_texture(texture_desc);

    init_gizmo();

    wb.register_developer_program("Inspector", draw_inspector_window, .Window, nil);
    wb.register_developer_program("Resources", draw_resources_window, .Window, nil);
    wb.register_developer_program("Hierarchy", draw_scene_hierarchy , .Window, nil);

    register_modal("Select Entity", draw_entity_select_modal, nil);
}

update :: proc(dt: f32) {
    gizmo_new_frame();
    
    // Get entity mouse is hovering
    {
        pixels := wb.get_texture_pixels(&entity_id_buffer_cpu_copy);
        defer wb.return_texture_pixels(&entity_id_buffer_cpu_copy, pixels);

        hovered_entity_index = -1;

        pixels_int := mem.slice_data_cast([]i32, pixels);
        idx := cast(int)wb.main_window.mouse_position_pixel.x + cast(int)(wb.main_window.height - wb.main_window.mouse_position_pixel.y) * entity_id_buffer_cpu_copy.width;
        if idx >= 0 && idx < len(pixels_int) {
            hovered_entity_index = cast(int)pixels_int[idx];
        }
    }

    if wb.get_input(.Mouse_Right) {

    }

    selected_count := len(selected_entities);
    if selected_count == 1 {
        selected_entity := entity.get_entity(selected_entities[0]);

        @static move_action: Memory_Action;
        @static rotate_action: Memory_Action;
        @static scale_action: Memory_Action;
        if !gizmo_state.is_manipulating {
            move_action   = create_memory_action(&selected_entity.position);
            rotate_action = create_memory_action(&selected_entity.rotation);
            scale_action  = create_memory_action(&selected_entity.scale);
        }

        gizmo_result := gizmo_manipulate(&selected_entity.position, &selected_entity.scale, &selected_entity.rotation, &g_editor_camera, &gizmo_state);
        if gizmo_result != nil {
            switch k in gizmo_result {
                case Gizmo_Move:   commit_memory_action(move_action);
                case Gizmo_Rotate: commit_memory_action(rotate_action);   
                case Gizmo_Scale:  commit_memory_action(scale_action);
            }
        }
    } 
    else if selected_count > 1 {
        // TODO put the gizmo in the center, and affect all selected things
    }

    if wb.get_input_down(.Mouse_Left, true) {
        select_entity(hovered_entity_index, !wb.get_input(.Control));
    }

    if wb.get_input_down(.Z, true) && wb.get_input(.Control) {
        if wb.get_input(.Shift) do redo();
        else do undo();
    }

    for modal in &modals {
        if modal.is_open && !imgui.is_popup_open(modal.name) do
            imgui.open_popup(modal.name);
        if !imgui.begin_popup_modal(modal.name, &modal.is_open) do return;
        defer imgui.end_popup();
        modal.procedure(&modal, modal.userdata);
    }
}

draw_inspector_window :: proc(userdata: rawptr) {
    // No multi selection for now
    if imgui.begin("Entity Inspector") && len(selected_entities) == 1 {
        selected_entity := entity.get_entity(selected_entities[0]);

        // Name
        @static name_buffer: [256]u8;
        bprint(name_buffer[:], selected_entity.name);
        selected_entity.name = do_input_text(name_buffer[:]);

        // Enabled
        imgui.same_line();
        imgui.checkbox("Enabled", &selected_entity.active);

        // Maybe tags? 

        // Transform info
        imgui.separator();
        imgui.text("Transform"); 
        {
            imgui.push_id("pos");
            defer imgui.pop_id();

            imgui.text("Position"); imgui.same_line();

            imgui.push_item_width(100);
            defer imgui.pop_item_width();
            
            imgui.input_float("x", &selected_entity.position.x); imgui.same_line();
            imgui.input_float("y", &selected_entity.position.y); imgui.same_line();
            imgui.input_float("z", &selected_entity.position.z);
        }

        {
            imgui.push_id("rot");
            defer imgui.pop_id();

            // x,y,z := la.pitch_yaw_roll_from_quaternion(selected_entity.rotation);
            // x = x * la.RAD_PER_DEG; y = y * la.RAD_PER_DEG; z = z * la.RAD_PER_DEG;
            // defer {
            //     x = x * la.DEG_PER_RAD; y = y * la.DEG_PER_RAD; z = z * la.DEG_PER_RAD;
            //     selected_entity.rotation = la.quaternion_from_pitch_yaw_roll(x, y, z);
            // }

            imgui.text("Rotation"); imgui.same_line();
            
            imgui.push_item_width(100); 
            defer imgui.pop_item_width();
            
            imgui.input_float("x", &selected_entity.rotation.x); imgui.same_line();
            imgui.input_float("y", &selected_entity.rotation.y); imgui.same_line();
            imgui.input_float("z", &selected_entity.rotation.y); imgui.same_line();
            imgui.input_float("w", &selected_entity.rotation.z);
        }

        {
            imgui.push_id("scale");
            defer imgui.pop_id();

            imgui.text("Scale"); imgui.same_line();
            
            imgui.push_item_width(100);
            defer imgui.pop_item_width();
            
            imgui.input_float("x", &selected_entity.scale.x); imgui.same_line();
            imgui.input_float("y", &selected_entity.scale.y); imgui.same_line();
            imgui.input_float("z", &selected_entity.scale.z);
        }

        // Entity types can sub their own editors in, if they want special things
        // otherwise generic, and uses tags on fields to modify things

    } imgui.end();
}

draw_inspector_ti :: proc(entity: ^Entity, name: string, ptr: rawptr, ti: ^runtime.Type_Info) {
    imgui.push_id(name);
    defer imgui.pop_id();
}

draw_scene_hierarchy :: proc(userdata: rawptr) {
    if !imgui.begin("Hierarchy") do return;
    defer imgui.end();

    if imgui.begin_popup_context_item("context menu") {

        if imgui.menu_item("Add Entity") do
            open_modal("Select Entity");

        imgui.end_popup();
    }
}

draw_resources_window :: proc(userdata: rawptr) {
    if !imgui.begin("Resources") do return;
    defer imgui.end();
}

draw_entity_select_modal :: proc(modal: ^Modal, userdata: rawptr) {

    for tid in entity.entity_typeids {
    }
    // draw all the entity types
    // allow user to select and create
    // allow user to cancel
}

render :: proc(render_graph: ^wb.Render_Graph, ctxt: ^shared.Render_Graph_Context) {
    wb.add_render_graph_node(render_graph, "entity id texture", ctxt, 
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.read_resource(render_graph, "scene draw list");
            wb.has_side_effects(render_graph);
        },
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            render_context := cast(^shared.Render_Graph_Context)userdata;

            draw_commands := wb.get_resource(render_graph, "scene draw list", []Draw_Command);

            pass_desc: wb.Render_Pass;
            pass_desc.camera = render_context.target_camera;
            pass_desc.color_buffers[0] = &entity_id_color_buffer;
            pass_desc.depth_buffer     = &entity_id_depth_buffer;
            wb.BEGIN_RENDER_PASS(&pass_desc);

            for cmd in draw_commands {
                e := cast(^entity.Entity)cmd.userdata;
                id_material := wb.g_materials["entity_id_mtl"]; 
                wb.set_material_property(id_material, "entity_id", cast(i32)e.id);
                wb.draw_model(cmd.model, cmd.position, cmd.scale, cmd.orientation, id_material);
            }

            wb.ensure_texture_size(&entity_id_buffer_cpu_copy, entity_id_color_buffer.width, entity_id_color_buffer.height);
            wb.copy_texture(&entity_id_buffer_cpu_copy, &entity_id_color_buffer);
        });

    wb.add_render_graph_node(render_graph, "gizmo", ctxt,
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            wb.has_side_effects(render_graph);
        },
        proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
            render_context := cast(^shared.Render_Graph_Context)userdata;
            gizmo_render(render_graph, render_context.editor_im_context);
        });
}

//
//

selected_entities: [dynamic]int;

select_entity :: proc(eid: int, override_selection: bool = true) {
    if override_selection {
        clear(&selected_entities);
    }

    if eid > 0 {
        for e in selected_entities {
            if e == eid do return;
        }
        append(&selected_entities, eid);
    }
}

//
//

Modal :: struct {
    name: string,
    procedure: proc(^Modal, rawptr),
    userdata: rawptr,
    is_open: bool,

    action: proc(userdata: rawptr, modal_data: rawptr),
}

modals: [dynamic]Modal;

register_modal :: proc(name: string, procedure: proc(^Modal, rawptr), userdata: rawptr, action: proc(userdata: rawptr, modal_data: rawptr) = nil) {
    append(&modals, Modal{name, procedure, userdata, false, action});
}

open_modal :: proc(name: string) {
    for modal in &modals {
        if modal.name == name {
            modal.is_open = true;
            break;
        }
    }
}

close_modal :: proc(name: string) {
    for modal in &modals {
        if modal.name == name {
            modal.is_open = false;
            break;
        }
    }
}


do_input_text :: proc(buf: []byte) -> string {
    imgui.input_text("", buf);
    buf[len(buf)-1] = 0;
    text := cast(string)cast(cstring)&buf[0];
    return text;
}

Draw_Command :: shared.Draw_Command;
Entity :: entity.Entity;

tprint   :: fmt.tprint;
tprintf  :: fmt.tprintf;
tprintln :: fmt.tprintln;
aprint   :: fmt.aprint;
aprintf  :: fmt.aprintf;
aprintln :: fmt.aprintln;
bprint   :: fmt.bprint;
bprintf  :: fmt.bprintf;
bprintln :: fmt.bprintln;
print   :: fmt.print;
printf  :: fmt.printf;
println :: fmt.println;
sbprint   :: fmt.sbprint;
sbprintf  :: fmt.sbprintf;
sbprintln :: fmt.sbprintln;
panicf :: fmt.panicf;

logln :: logging.logln;
logf :: logging.logf;
pretty_print :: logging.pretty_print;

Vector2 :: wb.Vector2;
Vector3 :: wb.Vector3;
Vector4 :: wb.Vector4;
Quaternion :: wb.Quaternion;
Matrix4 :: wb.Matrix4;

TAU :: math.TAU;
PI  :: math.PI;

pow                :: math.pow;
to_radians         :: math.to_radians_f32;
to_radians_f64     :: math.to_radians_f64;
to_degrees         :: math.to_degrees_f32;
to_degrees_f64     :: math.to_degrees_f64;
ortho3d            :: la.matrix_ortho3d;
perspective        :: la.matrix4_perspective;
transpose          :: la.transpose;
translate          :: la.matrix4_translate;
mat4_scale         :: la.matrix4_scale;
mat4_inverse       :: la.matrix4_inverse;
quat_to_mat4       :: la.matrix4_from_quaternion;
mul                :: la.mul;
length             :: la.length;
norm               :: la.normalize;
dot                :: la.dot;
cross              :: la.cross;
asin               :: math.asin;
acos               :: math.acos;
atan               :: math.atan;
atan2              :: math.atan2;
floor              :: math.floor;
ceil               :: math.ceil;
cos                :: math.cos;
sin                :: math.sin;
sqrt               :: math.sqrt;
slerp              :: la.quaternion_slerp;
quat_norm          :: la.quaternion_normalize;
angle_axis         :: la.quaternion_angle_axis;
identity           :: la.identity;
quat_inverse       :: la.quaternion_inverse;
lerp               :: math.lerp;
quat_mul_vec3      :: la.quaternion_mul_vector3;
mod                :: math.mod;

to_vec2 :: basic.to_vec2;
to_vec3 :: basic.to_vec3;
to_vec4 :: basic.to_vec4;
pretty_location :: basic.pretty_location;