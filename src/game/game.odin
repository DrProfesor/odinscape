package game

import "core:fmt"
import "core:strings"
import "core:mem"
import "core:os"
import "core:math"
import la "core:math/linalg"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb/stb"

import "../shared"
import "../configs"
import "../net"
import "../entity"

g_game_camera: wb.Camera;
g_cbuffer_lighting: wb.CBuffer;
g_color_buffer: wb.Texture;
g_depth_buffer: wb.Texture;
g_skybox: wb.Texture;

init :: proc() {

	if net.is_client {
		wb.track_asset_folder("resources/shaders/src");
		wb.track_asset_folder("resources/shaders/shaders");
		wb.track_asset_folder("resources/shaders/materials");
		
		wb.track_asset_folder("resources/character");
		wb.track_asset_folder("resources/creature");
		wb.track_asset_folder("resources/data");
		wb.track_asset_folder("resources/fonts");
		wb.track_asset_folder("resources/models");
		wb.track_asset_folder("resources/prefabs");
		wb.track_asset_folder("resources/scenes");
		wb.track_asset_folder("resources/textures");

		// wb.main_camera.is_perspective = true;
		// wb.main_camera.size = 70;
		// wb.main_camera.position = math.Vec3{0, 6.09, 4.82};
		// wb.main_camera.rotation = math.Quat{0,0,0,1};

		// wb.init_particles();
		// wb.init_terrain(); // we still need terrain collision on the server
		init_terrain();

		wb.init_camera(&g_game_camera);
		g_game_camera.is_perspective = true;
		
		g_cbuffer_lighting = wb.create_cbuffer_from_struct(CBuffer_Lighting);

		g_color_buffer, g_depth_buffer = wb.create_color_and_depth_buffers(shared.WINDOW_SIZE_X, shared.WINDOW_SIZE_Y, .R8G8B8A8_UINT);


		width: i32;
	    height: i32;
	    channels: i32;
	    data1, ok1 := os.read_entire_file("resources/skyboxes/1/wbcubemap_snob_right.png");  assert(ok1); pixel_data1 := stb.load_from_memory(&data1[0], cast(i32)len(data1), &width, &height, &channels, 4);
	    data2, ok2 := os.read_entire_file("resources/skyboxes/1/wbcubemap_snob_left.png");   assert(ok2); pixel_data2 := stb.load_from_memory(&data2[0], cast(i32)len(data2), &width, &height, &channels, 4);
	    data3, ok3 := os.read_entire_file("resources/skyboxes/1/wbcubemap_snob_top.png");    assert(ok3); pixel_data3 := stb.load_from_memory(&data3[0], cast(i32)len(data3), &width, &height, &channels, 4);
	    data4, ok4 := os.read_entire_file("resources/skyboxes/1/wbcubemap_snob_bottom.png"); assert(ok4); pixel_data4 := stb.load_from_memory(&data4[0], cast(i32)len(data4), &width, &height, &channels, 4);
	    data5, ok5 := os.read_entire_file("resources/skyboxes/1/wbcubemap_snob_front.png");  assert(ok5); pixel_data5 := stb.load_from_memory(&data5[0], cast(i32)len(data5), &width, &height, &channels, 4);
	    data6, ok6 := os.read_entire_file("resources/skyboxes/1/wbcubemap_snob_back.png");   assert(ok6); pixel_data6 := stb.load_from_memory(&data6[0], cast(i32)len(data6), &width, &height, &channels, 4);

		faces: [6]^byte;
	    faces[0] = pixel_data1;
	    faces[1] = pixel_data2;
	    faces[2] = pixel_data3;
	    faces[3] = pixel_data4;
	    faces[4] = pixel_data5;
	    faces[5] = pixel_data6;
	    cubemap_desc := wb.Texture_Description{type = .Cubemap, width = cast(int)width, height = cast(int)height, format = .R8G8B8A8_UINT};
	    g_skybox = wb.create_texture(cubemap_desc);
	    wb.set_cubemap_textures(&g_skybox, faces);
	}

	configs.add_config_load_listener(entity.on_config_load);

	init_players();

	entity.load_scene("main", true);
}

update :: proc(dt: f32) {
	
	if net.is_client {
		update_login_screen();
		update_character_select_screen();
	}

	if !net.is_logged_in && !net.is_server {
		// wait until we are connected
		return;
	}

	update_players(dt);
	update_terrain();

    // if wb.debug_window_open do return;
}

render :: proc(render_graph: ^wb.Render_Graph, ctxt: ^shared.Render_Graph_Context) {
	// build draw commands
	wb.add_render_graph_node(render_graph, "build draw", ctxt, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			wb.create_resource(render_graph, "scene draw list", []Draw_Command);
			wb.create_resource(render_graph, "scene lighting", CBuffer_Lighting);
		}, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			cmds: [dynamic]Draw_Command;
			lighting: CBuffer_Lighting;

			get_simple_model_renderer_command :: proc(model_renderer: entity.Model_Renderer, entity: ^Entity) -> Draw_Command {

				model : ^wb.Model;
				if model_renderer.model_id in wb.g_models {
					model = wb.g_models[model_renderer.model_id];
				} else {
					model = wb.g_models["cube_model"];
				}

				material : ^wb.Material;
				if model_renderer.material_id in wb.g_materials {
					material = wb.g_materials[model_renderer.material_id];
				} else {
					material = wb.g_materials["simple_rgba_mtl"];
				}

				return Draw_Command {
					model,
					entity.position,
					entity.scale,
					entity.rotation,
					material,
					model_renderer.tint,
					entity
				};
			}

			for player in entity.all_Player_Character {
				cmd := get_simple_model_renderer_command(player.model, cast(^Entity)player);
				append(&cmds, cmd);
			}

			for simple_model in entity.all_Simple_Model {
				cmd := get_simple_model_renderer_command(simple_model.model, cast(^Entity)simple_model);
				append(&cmds, cmd);
			}

			wb.set_resource(render_graph, "scene lighting", lighting, nil);
			wb.set_resource(render_graph, "scene draw list", cmds[:], nil);
		}); 
	// end build draw commands

	// draw shadows
	Cascaded_Shadow_Maps :: struct {
	    render_targets: [shared.NUM_SHADOW_MAPS]^wb.Texture,
	    matrices: [shared.NUM_SHADOW_MAPS]Matrix4,
	};
	wb.add_render_graph_node(render_graph, "shadows", ctxt, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			wb.read_resource(render_graph, "scene draw list");
	        wb.read_resource(render_graph, "scene lighting");
	        wb.create_resource(render_graph, "scene shadow map", Cascaded_Shadow_Maps);
		}, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			shadow_maps: Cascaded_Shadow_Maps;
			defer {
				lighting := wb.get_resource(render_graph, "scene lighting", CBuffer_Lighting);
				submit_sun(lighting, wb.construct_perspective_matrix(wb.to_radians(60), shared.WINDOW_SIZE_X / shared.WINDOW_SIZE_Y, 0.1, 1000), wb.construct_view_matrix({0,100,0}, wb.Quaternion(1)), {-60, -60, 0}, Vector3{1,1,1}, 10);
				wb.set_resource(render_graph, "scene shadow map", shadow_maps, nil);
			}

			if len(entity.all_Directional_Light) == 0 do return;
			
			sun := entity.all_Directional_Light[0];

			cascade_distances := [shared.NUM_SHADOW_MAPS+1]f32{0, 10, 20, 30, 1000};
            for map_idx in 0..<shared.NUM_SHADOW_MAPS {
                shadow_camera := &sun.cameras[map_idx];
                shadow_color_buffer := &sun.color_buffers[map_idx];
                shadow_depth_buffer := &sun.depth_buffers[map_idx];
                frustum_corners := [8]Vector3 {
                    {-1,  1, -1},
                    { 1,  1, -1},
                    { 1, -1, -1},
                    {-1, -1, -1},
                    {-1,  1,  1},
                    { 1,  1,  1},
                    { 1, -1,  1},
                    {-1, -1,  1},
                };

                // calculate sub-frustum for this cascade
                cascade_proj := perspective(to_radians(g_game_camera.size), f32(wb.main_window.width) / wb.main_window.height, g_game_camera.near_plane + cascade_distances[map_idx], min(g_game_camera.far_plane, g_game_camera.near_plane + cascade_distances[map_idx+1]), false);
                cascade_view := wb.construct_view_matrix(g_game_camera.position, g_game_camera.orientation);
                cascade_viewport_to_world := mat4_inverse(mul(cascade_proj, cascade_view));

                transform_point :: proc(matrix: Matrix4, pos: Vector3) -> Vector3 {
                    pos4 := to_vec4(pos);
                    pos4.w = 1;
                    pos4 = mul(matrix, pos4);
                    if pos4.w != 0 do pos4 /= pos4.w;
                    return to_vec3(pos4);
                }



                // calculate center point and radius of frustum
                center_point: Vector3;
                for _, idx in frustum_corners {
                    frustum_corners[idx] = transform_point(cascade_viewport_to_world, frustum_corners[idx]);
                    center_point += frustum_corners[idx];
                }
                center_point /= len(frustum_corners);



                // todo(josh): this radius changes very slightly as the camera rotates around for some reason. this shouldn't be happening and I believe it's causing the flickering
                // note(josh): @ShadowFlickerHack hacked around the problem by clamping the radius to an int. pretty shitty, should investigate a proper solution
                radius := cast(f32)cast(int)(length(frustum_corners[0] - frustum_corners[6]) / 2 + 1.0);

                light_rotation := sun.rotation;
                light_direction := quaternion_forward(light_rotation);

                texels_per_unit := SHADOW_MAP_DIM / (radius * 2);
                scale_matrix := mat4_scale(Vector3{texels_per_unit, texels_per_unit, texels_per_unit});
                scale_matrix = mul(scale_matrix, quat_to_mat4(quat_inverse(light_rotation)));

                center_point_texel_space := transform_point(scale_matrix, center_point);
                center_point_texel_space.x = round(center_point_texel_space.x);
                center_point_texel_space.y = round(center_point_texel_space.y);
                center_point_texel_space.z = round(center_point_texel_space.z);
                center_point = transform_point(mat4_inverse(scale_matrix), center_point_texel_space);

                // position the shadow camera looking at that point
                shadow_camera.position = center_point - light_direction * radius;
                shadow_camera.orientation = light_rotation;
                shadow_camera.size = radius;
                shadow_camera.far_plane = radius * 2;

                shadow_pass_desc: wb.Render_Pass;
                shadow_pass_desc.camera = shadow_camera;
                shadow_pass_desc.color_buffers[0] = shadow_color_buffer;
                shadow_pass_desc.depth_buffer     = shadow_depth_buffer;
                shadow_pass_desc.clear_color      = {1, 1, 1, 1};
                shadow_pass_desc.dont_resize_render_targets_to_screen = true;
                wb.BEGIN_RENDER_PASS(&shadow_pass_desc);
                shadow_maps.matrices[map_idx] = mul(shadow_camera.projection_matrix, shadow_camera.view_matrix);

                shadow_material := wb.g_materials["shadow_mtl"];
                draw_commands := wb.get_resource(render_graph, "scene draw list", []Draw_Command);
                wb.BIND_MATERIAL(shadow_material);
                for cmd in draw_commands {
                    if len(cmd.model.meshes) > 0 {
                        wb.draw_model_no_material(cmd.model, cmd.position, cmd.scale, cmd.orientation, cmd.color);
                    }
                }

                shadow_maps.render_targets[map_idx] = shadow_color_buffer;
            }
		});

	// TODO draw bloom
	// TODO ambient occlusion
	// TODO auto exposure
	// TODO fog

	// draw scene
	wb.add_render_graph_node(render_graph, "draw", ctxt, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			wb.read_resource(render_graph, "scene draw list");
            wb.read_resource(render_graph, "scene lighting");
            wb.read_resource(render_graph, "scene shadow map");
            wb.create_resource(render_graph, "game view color", wb.Texture);
            wb.create_resource(render_graph, "game view depth", wb.Texture);
		}, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			render_context := cast(^shared.Render_Graph_Context)userdata;

			lighting := wb.get_resource(render_graph, "scene lighting", CBuffer_Lighting);
            wb.flush_cbuffer_from_struct(&g_cbuffer_lighting, lighting^);
            wb.bind_cbuffer(&g_cbuffer_lighting, cast(int)CBuffer_Slot.Lighting);

            {
				shadow_maps := wb.get_resource(render_graph, "scene shadow map", Cascaded_Shadow_Maps);
				if shadow_maps.render_targets[0] != nil {
		            for render_target, idx in &shadow_maps.render_targets {
		                wb.bind_texture(render_target, cast(int)Texture_Slot.Shadow_Map1+idx);
		            }
		            defer for _, idx in &shadow_maps.render_targets {
		                wb.bind_texture(nil, cast(int)Texture_Slot.Shadow_Map1+idx);
		            }
		        }

	            pass: wb.Render_Pass;
	            pass.camera = render_context.target_camera;
	            pass.color_buffers[0] = &g_color_buffer;
	            pass.depth_buffer = &g_depth_buffer;
	            wb.BEGIN_RENDER_PASS(&pass);

	            // skybox
	            skybox_mtl := wb.g_materials["skybox_mtl"];
	            wb.set_material_texture(skybox_mtl, "albedo_map", &g_skybox, .Wrap_Linear);
	            wb.draw_model(wb.g_models["cube_model"], render_context.target_camera.position, {1, 1, 1}, Quaternion(1), skybox_mtl);

	            draw_commands := wb.get_resource(render_graph, "scene draw list", []Draw_Command);
	            for cmd in draw_commands {
	                if len(cmd.model.meshes) > 0 {
	                    wb.draw_model(cmd.model, cmd.position, cmd.scale, cmd.orientation, cmd.material_override, cmd.color);
	                }
	            }
        	}

            wb.set_resource(render_graph, "game view color", g_color_buffer, nil);
            wb.set_resource(render_graph, "game view depth", g_depth_buffer, nil);
		});
	// end draw scene
	
	// wb.set_sun_data(math.degrees_to_quaternion({-60, -60, 0}), {1, 1, 1, 1}, 10);
}

shutdown :: proc() {
	
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

MAX_LIGHTS :: 16;
CBuffer_Lighting :: struct {
    point_light_positions:   [MAX_LIGHTS]Vector4,
    point_light_colors:      [MAX_LIGHTS]Vector4,
    point_light_intensities: [MAX_LIGHTS]Vector4,
    num_point_lights: i32,
    sun_direction: Vector3,
    sun_color: Vector3,
    sun_intensity: f32,
    sun_matrix: Matrix4,
    shadow_map_dimensions: Vector2,
}

submit_point_light :: proc(cbuffer: ^CBuffer_Lighting, position: Vector3, color: Vector3, intensity: f32) {
    if cbuffer.num_point_lights >= MAX_LIGHTS {
        return;
    }
    cbuffer.point_light_positions  [cbuffer.num_point_lights] = Vector4{position.x, position.y, position.z, 0};
    cbuffer.point_light_colors     [cbuffer.num_point_lights] = Vector4{color.x, color.y, color.z, 0};
    cbuffer.point_light_intensities[cbuffer.num_point_lights] = intensity;
    cbuffer.num_point_lights += 1;
}

SHADOW_MAP_DIM :: 2048;
submit_sun :: proc(cbuffer: ^CBuffer_Lighting, proj, view: Matrix4, direction: Vector3, color: Vector3, intensity: f32) { // todo(josh): we won't need position and orientation here when we do cascades
    cbuffer.sun_direction = direction;
    cbuffer.sun_color = color;
    cbuffer.sun_intensity = intensity;
    cbuffer.sun_matrix = wb.mul(proj, view);
    cbuffer.shadow_map_dimensions = {SHADOW_MAP_DIM, SHADOW_MAP_DIM};
}


Entity :: entity.Entity;
Player_Character :: entity.Player_Character;
Spell_Caster :: entity.Spell_Caster;
Spell :: entity.Spell;
Spell_Type :: entity.Spell_Type;
Spell_Config_Data :: entity.Spell_Config_Data;

Draw_Command :: shared.Draw_Command;

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


TAU :: math.TAU;
PI  :: math.PI;

Vector2 :: la.Vector2;
Vector3 :: la.Vector3;
Vector4 :: la.Vector4;
Matrix4 :: la.Matrix4;
Quaternion :: la.Quaternion;

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


quat_look_at            :: wb.quat_look_at;
degrees_to_quaternion   :: wb.degrees_to_quaternion;
direction_to_quaternion :: wb.direction_to_quaternion;
quaternion_to_euler     :: wb.quaternion_to_euler;

move_towards :: wb.move_towards;

sbwrite :: wb.sbwrite;
twrite  :: wb.twrite;

quaternion_right   :: wb.quaternion_right;
quaternion_up      :: wb.quaternion_up;
quaternion_forward :: wb.quaternion_forward;
quaternion_left    :: wb.quaternion_left;
quaternion_down    :: wb.quaternion_down;
quaternion_back    :: wb.quaternion_back;

round_to_f32 :: wb.round_to_f32;
round_to_f64 :: wb.round_to_f64;
round        :: wb.round;


to_vec2 :: basic.to_vec2;
to_vec3 :: basic.to_vec3;
to_vec4 :: basic.to_vec4;
pretty_location :: basic.pretty_location;