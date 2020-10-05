package game

import "core:fmt"
import "core:mem"
import "core:os"

import "shared:wb"
import "shared:wb/basic"
import "shared:wb/logging"

import "../shared"
import "../configs"
import "../net"
import "../entity"

g_game_camera: wb.Camera;
g_cbuffer_lighting: wb.CBuffer;

init :: proc() {

	if net.is_client {
		wb.track_asset_folder("resources");

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
	}

	configs.add_config_load_listener(entity.on_config_load);

	init_players();
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

render :: proc(render_graph: ^wb.Render_Graph) {
	// build draw commands
	wb.add_render_graph_node(render_graph, "build draw", nil, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			wb.create_resource(render_graph, "scene draw list", []Draw_Command);
			wb.create_resource(render_graph, "scene lighting", CBuffer_Lighting);
		}, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			cmds: [dynamic]Draw_Command;
			lighting: CBuffer_Lighting;

			for player in entity.player_characters {
				player_entity := cast(^entity.Entity)player;
				cmd := Draw_Command {
					wb.g_models[player.model_id],
					player_entity.position,
					player_entity.scale,
					player_entity.rotation,
					wb.g_materials["simple_rgba_mtl"],
					{ 1, 1, 1, 1 },
					nil,
				};
				append(&cmds, cmd);
			}

			submit_sun(&lighting, wb.construct_perspective_matrix(wb.to_radians(60), 1920/1080, 0.1, 1000), wb.construct_view_matrix({0,100,0}, wb.Quaternion(1)), {-60, -60, 0}, Vector3{1,1,1}, 10);

			wb.set_resource(render_graph, "scene draw list", cmds[:], nil);
            wb.set_resource(render_graph, "scene lighting", lighting, nil);			
		}); 
	// end build draw commands

	// draw scene
	wb.add_render_graph_node(render_graph, "draw", nil, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			wb.read_resource(render_graph, "scene draw list");
            wb.read_resource(render_graph, "scene lighting");
            wb.create_resource(render_graph, "game view color", wb.Texture);
            wb.create_resource(render_graph, "game view depth", wb.Texture);
		}, 
		proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
			lighting := wb.get_resource(render_graph, "scene lighting", CBuffer_Lighting);
            wb.flush_cbuffer_from_struct(&g_cbuffer_lighting, lighting^);
            wb.bind_cbuffer(&g_cbuffer_lighting, cast(int)CBuffer_Slot.Lighting);

            color_buffer, depth_buffer := wb.create_color_and_depth_buffers(1920, 1080, .R8G8B8A8_UINT);
            
            {
	            pass: wb.Render_Pass;
	            pass.camera = &g_game_camera;
	            pass.color_buffers[0] = &color_buffer;
	            pass.depth_buffer = &depth_buffer;
	            pass.resize_render_targets_to_screen = true;
	            wb.BEGIN_RENDER_PASS(&pass);

	            draw_commands := wb.get_resource(render_graph, "scene draw list", []Draw_Command);
	            for cmd in draw_commands {
	                if len(cmd.model.meshes) > 0 {
	                    wb.draw_model(cmd.model, cmd.position, cmd.scale, cmd.orientation, cmd.material_override, cmd.color);
	                }
	            }
        	}

            wb.set_resource(render_graph, "game view color", color_buffer, nil);
            wb.set_resource(render_graph, "game view depth", depth_buffer, nil);
		});
	// end draw scene
	
	// wb.set_sun_data(math.degrees_to_quaternion({-60, -60, 0}), {1, 1, 1, 1}, 10);
}

shutdown :: proc() {
	
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

Draw_Command :: struct {
    model:             ^wb.Model,
    position:          Vector3,
    scale:             Vector3,
    orientation:       Quaternion,
    material_override: ^wb.Material,
    color:             Vector4,
    userdata:          rawptr,
}

logln :: logging.logln;

Vector2 :: wb.Vector2;
Vector3 :: wb.Vector3;
Vector4 :: wb.Vector4;
Quaternion :: wb.Quaternion;
Matrix4 :: wb.Matrix4;

Entity :: entity.Entity;
Player_Character :: entity.Player_Character;
Spell_Caster :: entity.Spell_Caster;
Spell :: entity.Spell;
Spell_Type :: entity.Spell_Type;
Spell_Config_Data :: entity.Spell_Config_Data;