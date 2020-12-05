package editor

import la "core:math/linalg"
import "core:math"
import "core:slice"

import "shared:wb"
import "shared:wb/d3d"

import "../configs"
import "../entity"
import "../shared"
import "../util"
import "../physics"

g_voxelizer_camera: wb.Camera;
g_positive_voxelizer_texture: wb.Texture;
g_negative_voxelizer_texture: wb.Texture;
g_positive_voxelizer_read_texture: wb.Texture;
g_negative_voxelizer_read_texture: wb.Texture;

g_cutting_shape_texture: wb.Texture;
g_cutting_shape_texture_depth: wb.Texture;
g_cutting_shape_read_texture: wb.Texture;
g_cutting_shape_in_tex: wb.Texture;

DETAIL_MULTIPLIER :: 4;
SLICEMAP_SIZE :: 128;
SLICEMAP_DEPTH :: 128;

MAX_WALK_ANGLE : f32 = 45;
PLAYER_HEIGHT : f32 = 4;
PLAYER_STEP_HEIGHT : f32 = 0.3;

g_current_slicemap: [SLICEMAP_SIZE][SLICEMAP_SIZE]u128;
g_current_negative_slicemap: [SLICEMAP_SIZE][SLICEMAP_SIZE]u128;
g_cutting_shape_data: [SLICEMAP_SIZE*SLICEMAP_SIZE]Vector4;

colours : []Vector4 = { {1,0,0,0.5}, {1,0.5,0.1,0.5}, {0,1,0,0.5}, {0.1,1,0.5,0.5}, {0,1,1,0.5}, {0,0.5,1,0.5}, {0.2,0,1,0.5}, {0.6,0,1,0.5}, {1,0,1,0.5} };
orthogonal_cells := [4]Vector3{{-1,0,0}, {1,0,0}, {0,0,1}, {0,0,-1}};
adjacent_cells := [8]Vector3{{-1,0,0}, {-1, 0, 1}, {0,0,1}, {1,0,1}, {1,0,0}, {1, 0, -1}, {0,0,-1}, {-1, 0, -1}};

Layer :: struct { 
	floor_plan: [dynamic]Floor_Vertex,
	objects: [dynamic]Layer_Object,
	cells: [dynamic]u64,  
}
Layer_Object :: struct {
	verts: [dynamic]Floor_Vertex,
	ordered_verts: [dynamic]Floor_Vertex,
	is_obstacle: bool,
}
Floor_Vertex :: struct {
	using position: Vector3,
	is_obstacle: bool,
	cell_x, cell_z: int,
}
layers: [128]Layer;
init_navmesh :: proc() {
    wb.init_camera(&g_voxelizer_camera);
    voxelizer_tex_desc := wb.Texture_Description {
        type = .Texture2D,
        width = SLICEMAP_SIZE,
        height = SLICEMAP_SIZE,
        format = .R32G32B32A32_UINT,
        render_target = true,
    };
    g_positive_voxelizer_texture = wb.create_texture(voxelizer_tex_desc);
    g_negative_voxelizer_texture = wb.create_texture(voxelizer_tex_desc);

    voxelizer_tex_desc.render_target = false;
    voxelizer_tex_desc.is_cpu_read_target = true;
    g_positive_voxelizer_read_texture = wb.create_texture(voxelizer_tex_desc);
    g_negative_voxelizer_read_texture = wb.create_texture(voxelizer_tex_desc);

    cs_tex_desc := wb.Texture_Description {
        type = .Texture2D,
        width = SLICEMAP_SIZE,
        height = SLICEMAP_SIZE,
        format = .R32G32B32A32_FLOAT,
        render_target = true,
    };
    cs_tex_desc.render_target = false;
    cs_tex_desc.is_cpu_read_target = true;
    g_cutting_shape_read_texture = wb.create_texture(cs_tex_desc);
    g_cutting_shape_texture, g_cutting_shape_texture_depth = wb.create_color_and_depth_buffers(SLICEMAP_SIZE, SLICEMAP_SIZE, .R32G32B32A32_FLOAT);
    g_cutting_shape_in_tex = wb.create_texture(wb.Texture_Description{type = .Texture2D, width = SLICEMAP_SIZE, height = SLICEMAP_SIZE, format = .R32G32B32A32_FLOAT, color_data = nil});
}

Gen_State :: enum {
	Coarse_Voxalization,
	Layer_Extraction,
	Layer_Refinement,
	Object_Classification,
	Mesh_Generation,
}

update_navmesh :: proc() {
}

current_gen_state: Gen_State;
single_frame := false;
render_navmesh :: proc(render_graph: ^wb.Render_Graph, ctxt: ^shared.Render_Graph_Context) {
	if should_regen_nav_mesh {
        wb.add_render_graph_node(render_graph, "scene voxelizer", ctxt, 
            proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
                wb.has_side_effects(render_graph);
                wb.read_resource(render_graph, "scene draw list");
            },
            proc(render_graph: ^wb.Render_Graph, userdata: rawptr) {
                render_context := cast(^shared.Render_Graph_Context)userdata;
                draw_commands := wb.get_resource(render_graph, "scene draw list", []Draw_Command);

                // Coarse voxalization
                if single_frame || current_gen_state == .Coarse_Voxalization {
					directions := [3]Vector3{{0,1,0}, {1,0,0}, {0,0,1}};
                    rotations := [3]Quaternion{la.quaternion_from_euler_angle_x(1.57), la.quaternion_from_euler_angle_y(1.57), Quaternion(1)};

                    voxelizer_material := wb.g_materials["voxelizer"];
                    wb.set_material_property(voxelizer_material, "max_angle", to_radians(MAX_WALK_ANGLE));

                    for direction, i in directions {
                        wb.set_material_property(voxelizer_material, "direction", cast(i32)i);
                        g_voxelizer_camera.position = direction * (SLICEMAP_DEPTH/2/DETAIL_MULTIPLIER);
                        g_voxelizer_camera.orientation = rotations[i];
                        g_voxelizer_camera.size = SLICEMAP_SIZE / (2*DETAIL_MULTIPLIER); // controls how detailed
                        wb.set_material_property(voxelizer_material, "depth", cast(i32)SLICEMAP_DEPTH/DETAIL_MULTIPLIER);

                        pass_desc: wb.Render_Pass;
                        pass_desc.camera = &g_voxelizer_camera;
                        pass_desc.color_buffers[0] = &g_positive_voxelizer_texture;
                        pass_desc.color_buffers[1] = &g_negative_voxelizer_texture;
                        pass_desc.dont_resize_render_targets_to_screen = true;
                        wb.BEGIN_RENDER_PASS(&pass_desc);

                        for cmd in draw_commands {
                            if cmd.entity == nil do continue;
                            e := cast(^entity.Entity)cmd.entity;
                            if !physics.entity_has_collision(e) do continue;
                            wb.draw_model(cmd.model, cmd.position, cmd.scale, cmd.orientation, voxelizer_material, {1,1,1,1});
                        }

                        wb.ensure_texture_size(&g_positive_voxelizer_read_texture, g_positive_voxelizer_texture.width, g_positive_voxelizer_texture.height);
                        wb.copy_texture(&g_positive_voxelizer_read_texture, &g_positive_voxelizer_texture);
                        p_pixels := wb.get_texture_pixels(&g_positive_voxelizer_read_texture);
                        defer wb.return_texture_pixels(&g_positive_voxelizer_read_texture, p_pixels);

                        wb.ensure_texture_size(&g_negative_voxelizer_read_texture, g_negative_voxelizer_texture.width, g_negative_voxelizer_texture.height);
                        wb.copy_texture(&g_negative_voxelizer_read_texture, &g_negative_voxelizer_texture);
                        n_pixels := wb.get_texture_pixels(&g_negative_voxelizer_read_texture);
                        defer wb.return_texture_pixels(&g_negative_voxelizer_read_texture, n_pixels);

                        pi_pixels := transmute([]u128)p_pixels;
                        ni_pixels := transmute([]u128)n_pixels;
                        for j in 0..<len(p_pixels)/16 {
                            if i == 0 {
                                x := j%SLICEMAP_SIZE;
                                z := j/SLICEMAP_SIZE;
                                g_current_slicemap[z][x] = pi_pixels[j];
                                g_current_negative_slicemap[z][x] = ni_pixels[j];
                            }
                            if i == 1 {
                                z := j%SLICEMAP_SIZE;
                                y := j/SLICEMAP_SIZE;
                                yb := u128(1) << u128(SLICEMAP_DEPTH-1-y);
                                for x in 0..<SLICEMAP_DEPTH {
                                    if ni_pixels[j] & (u128(1) << u128(x)) != 0 {
                                        g_current_negative_slicemap[z][x] |= yb;
                                    }
                                }
                            }
                            if i == 2 {
                                x := j%SLICEMAP_SIZE;
                                y := j/SLICEMAP_SIZE;
                                yb := u128(1) << u128(SLICEMAP_DEPTH-1-y);
                                for z in 0..<SLICEMAP_DEPTH {
                                    if ni_pixels[j] & (u128(1) << u128(z)) != 0 {
                                        g_current_negative_slicemap[SLICEMAP_SIZE-1-z][x] |= yb;
                                    }
                                }
                            }
                        }
                    }

                    current_gen_state = .Layer_Extraction;
                    if !single_frame do return;
                }

                

                // Layer extraction
                if single_frame || current_gen_state == .Layer_Extraction {
                	layers = {};
                    cells: map[u64]int; defer delete(cells);
                    current_layer_id := 0;
                    last_y := 0;

                    pass: wb.Render_Pass;
                    if pathing_debug_state == .Layer_Construction {
                        pass.camera = &g_editor_camera;
                        pass.color_buffers[0] = &debug_color_buffer;
                        pass.depth_buffer = &debug_depth_buffer;
                        wb.begin_render_pass(&pass);
                    }

                    for y in 0..<128 {
                        bit := cast(u128)1 << cast(u128)y;
                        for zs, z in g_current_slicemap {
                            for column, x in zs {
                                // negative_column := g_current_negative_slicemap[z][x];
                                // if negative_column & bit != 0 do continue;
                                if column & bit == 0 do continue; 

                                // If there is a cell below us start our layer id at 1+ the below cells id
                                if y > 0 do for yi := y-1; yi >= 0; yi -= 1 {
                                	below_cid := get_cell_id(x,yi,z);
                                	below_layer_id, cell_below := cells[below_cid];
                                	if !cell_below do continue;
                                	
                                	current_layer_id = below_layer_id + 1;
                                	break;
                                }

                                // Filter out cells that would have the player hit their head
                                can_fit := true;
                                for yi := y+1; yi <= y+int(PLAYER_HEIGHT); yi += 1 {
                                	height_check_bit := cast(u128)1 << cast(u128)yi;
                                	if g_current_slicemap[z][x] & height_check_bit != 0 || 
                                	   g_current_negative_slicemap[z][x] & height_check_bit != 0
                                	{
                            	       can_fit = false;
                            	       break;
                            	    }
                                }

                                if !can_fit do continue;

                                // Check nearby cells for an id to use
                                found_neighbour := false;
                                min_neighbour_id := 128;
                                for yi in -1..1 { y := y+yi;
                                    for oc in orthogonal_cells {
                                    	neighbour_layer_id,  neighbour_found := cells[get_cell_id(x+int(oc.x),y,z+int(oc.z))];
                                        if !neighbour_found do continue;
                                        min_neighbour_id = min(neighbour_layer_id, min_neighbour_id);
                                        found_neighbour = true;
                                    }
                                }

                                if !found_neighbour {
                                	current_layer_id += 1;
                                } else {
                                	current_layer_id = min_neighbour_id;
                                }

                                cid := get_cell_id(x,y,z);
                                cells[cid] = current_layer_id;
                                append(&layers[current_layer_id].cells, cid);
                                last_y = y;
                                col := current_layer_id>=len(colours) ? Vector4{0.5,0,0,0.5} : colours[current_layer_id];

                                // Check neighbours again and see if we need to merge any layers
                                for yi in -1..1 { y := y+yi;
                                    for oc in orthogonal_cells {
                                    	neighbour_id := get_cell_id(x+int(oc.x),y,z+int(oc.z));
                                    	neighbour_layer_id,  neighbour_found := cells[neighbour_id];
                                    	if neighbour_found && neighbour_layer_id != current_layer_id {
                                    		
                                    		// check for cells in the same column between layers
                                    		col = {col.x,col.y,col.z,1};
                                    		any_in_same_column := false;
                                            for c1 in layers[neighbour_layer_id].cells {
                                                for c2 in layers[current_layer_id].cells {
                                                    x1 := u32(i16(c1 >> 48));
                                                    z1 := u32(i16(c1 >> 32));

                                                    x2 := u32(i16(c2 >> 48));
                                                    z2 := u32(i16(c2 >> 32));
                                                    if x1 == x2 && z1 == z2 {
                                                        any_in_same_column = true;
                                                        break;
                                                    }
                                                }
                                            }

                                            // actually do the merge
                                            if !any_in_same_column {
                                            	col = {1,1,1,1};
                                                li_min := min(neighbour_layer_id, current_layer_id);
                                                li_max := max(neighbour_layer_id, current_layer_id);

                                                for c in layers[li_max].cells {
                                                    append(&layers[li_min].cells, c);
                                                    cells[c] = li_min;
                                                }
                                                clear(&layers[li_max].cells);
                                            }
                                    	}
                                    }
                                }

                                if pathing_debug_state == .Layer_Construction {
                                    cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, SLICEMAP_SIZE-f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / {DETAIL_MULTIPLIER,DETAIL_MULTIPLIER,DETAIL_MULTIPLIER};
                                    wb.draw_model(wb.g_models["cube_model"], cell_pos, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], col);
                                }
                            }
                        }
                    }

                    if pathing_debug_state == .Layer_Construction do wb.end_render_pass(&pass);

                    current_gen_state = .Layer_Refinement;
                    if !single_frame do return;
                }

                get_cell_id :: proc(x,y,z: int) -> u64 {
                    return transmute(u64) (((cast(u64)i16(x)) << 48) | ((cast(u64)i16(z)) << 32) | ((cast(u64)i16(y)) << 16));
                }

                // Layer refinement
                if single_frame || current_gen_state == .Layer_Refinement {
                    // TODO? Contour expansion
                    // expand accessible voxels around obstacles
                    // how??
                    if pathing_debug_state == .Layers {
                        pass: wb.Render_Pass;
                        pass.camera = &g_editor_camera;
                        pass.color_buffers[0] = &debug_color_buffer;
                        pass.depth_buffer = &debug_depth_buffer;
                        wb.BEGIN_RENDER_PASS(&pass);

                        l := 0;
                        for layer in layers {
                            if len(layer.cells) == 0 do continue;
                            for cell in layer.cells {
                                x := u32(i16(cell >> 48));
                                z := u32(i16(cell >> 32));
                                y := u32(i16(cell >> 16));
                                bit := cast(u128)1 << cast(u128)y;
	                            is_obstacle := g_current_negative_slicemap[z][x] & bit != 0;

	                            for yi := y+1; yi <= y+u32(PLAYER_HEIGHT); yi += 1 {
	                            	height_check_bit := cast(u128)1 << cast(u128)yi;
                                	if g_current_negative_slicemap[z][x] & height_check_bit != 0 ||
                                	   g_current_slicemap[z][x] & height_check_bit != 0 {
                                		is_obstacle = true;
                                	}
	                            }

	                            // colour := is_obstacle ? Vector4{1,0,0,0.5} : Vector4{0,1,0,0.5};
	                            colour := l >= len(colours) ? Vector4{0.5,0,0,0.5} : colours[l];
                                cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, SLICEMAP_SIZE-f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / {DETAIL_MULTIPLIER,DETAIL_MULTIPLIER,DETAIL_MULTIPLIER};
                                wb.draw_model(wb.g_models["cube_model"], cell_pos, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], colour);
                            }
                            l+=1;
                        }
                    }

                    layer_id := 0;
                    for layer in &layers {
                        if len(layer.cells) == 0 do continue;
                        defer layer_id += 1;

                        // Create the layers cutting shape
                        {
	                        g_cutting_shape_data = {};
	                        for cell in layer.cells {
	                            x := u32(i16(cell >> 48));
	                            z := u32(i16(cell >> 32));
	                            y := u32(i16(cell >> 16));

	                            bit := cast(u128)1 << cast(u128)y;
	                            is_obstacle := g_current_negative_slicemap[z][x] & bit != 0;

	                            for yi := y+1; yi <= y+u32(PLAYER_HEIGHT); yi += 1 {
	                            	height_check_bit := cast(u128)1 << cast(u128)yi;
                                	if g_current_negative_slicemap[z][x] & height_check_bit != 0 ||
                                	   g_current_slicemap[z][x] & height_check_bit != 0 {
                                		is_obstacle = true;
                                		break;
                                	}
	                            }
	                            
	                            cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, SLICEMAP_SIZE-f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / {DETAIL_MULTIPLIER,DETAIL_MULTIPLIER,DETAIL_MULTIPLIER};

	                            j := x + (z * SLICEMAP_SIZE);
	                            g_cutting_shape_data[j] = Vector4{is_obstacle ? 2 : 1,cell_pos.x,cell_pos.y,cell_pos.z};
	                        }

	                        // TODO(jake): Move to wb call
	                        wb.directx.device_context.UpdateSubresource(wb.directx.device_context, cast(^d3d.ID3D11Resource)g_cutting_shape_in_tex.handle.texture_handle.(^d3d.ID3D11Texture2D), 0, nil, cast(^byte)&g_cutting_shape_data, SLICEMAP_SIZE * size_of(Vector4i), 0);

	                        wb.bind_texture(&g_cutting_shape_in_tex, 0);
	                        defer wb.bind_texture(nil, 0);

	                        g_voxelizer_camera.position = {0,1,0} * (SLICEMAP_DEPTH/2/DETAIL_MULTIPLIER);
	                        g_voxelizer_camera.orientation = la.quaternion_from_euler_angle_x(1.57);
	                        g_voxelizer_camera.size = SLICEMAP_SIZE / (2*DETAIL_MULTIPLIER);

	                        depthmap_extractor := wb.g_materials["voxel_depthmap_extractor_mat"];
	                        wb.set_material_property(depthmap_extractor, "slicemap_size", cast(f32)SLICEMAP_SIZE);
	                        wb.set_material_property(depthmap_extractor, "cell_center_offset", cast(f32)0.5);
	                        wb.set_material_property(depthmap_extractor, "detail_multiplier", cast(f32)DETAIL_MULTIPLIER);
						
	                        pass_desc: wb.Render_Pass;
	                        pass_desc.camera = &g_voxelizer_camera;
	                        pass_desc.color_buffers[0] = &g_cutting_shape_texture;
	                        pass_desc.clear_color = {-1000,-1000,-1000,0};
	                        // pass_desc.depth_buffer = &g_cutting_shape_texture_depth;
	                        pass_desc.dont_resize_render_targets_to_screen = true;
	                        wb.BEGIN_RENDER_PASS(&pass_desc);

	                        for cmd in draw_commands {
	                            if cmd.entity == nil do continue;
	                            e := cast(^entity.Entity)cmd.entity;
	                            if !physics.entity_has_collision(e) do continue;

	                            wb.draw_model(cmd.model, cmd.position, cmd.scale, cmd.orientation, depthmap_extractor, {1,1,1,1});
	                        }

	                        // Obstacle detection and polygon reconstruction
	                        wb.ensure_texture_size(&g_cutting_shape_read_texture, g_cutting_shape_texture.width, g_cutting_shape_texture.height);
	                        wb.copy_texture(&g_cutting_shape_read_texture, &g_cutting_shape_texture);
                    	}

                    	// create the floor plan from the cutting shape
                    	{
							pass: wb.Render_Pass;
                    		if cast(int) layer_to_debug == layer_id && pathing_debug_state == .Vertex_Construction {
                        		pass.camera = &g_editor_camera;
		                        pass.color_buffers[0] = &debug_color_buffer;
		                        pass.depth_buffer = &debug_depth_buffer;
		                        wb.begin_render_pass(&pass);
                    		}

                    		pixels := wb.get_texture_pixels(&g_cutting_shape_read_texture);
	                        defer wb.return_texture_pixels(&g_cutting_shape_read_texture, pixels);

	                        _pixels := transmute([]Vector4)pixels;
	                        max := len(pixels)/16;
	                        for i in 0..<max {
	                            depth_val := _pixels[i].y;
	                            if depth_val <= -999 do continue; // min value set from above, this is empty space for this layer
	                            x := i%SLICEMAP_SIZE;
	                        	z := i/SLICEMAP_SIZE;
	                        	
	                        	pos := Vector3{_pixels[i].x,_pixels[i].y,_pixels[i].z};
	                        	
	                            for oc in adjacent_cells {
	                            	nx := x + int(oc.x);
	                            	nz := z + int(oc.z);
	                            	neighbour_idx := nx + nz*SLICEMAP_SIZE;
	                            	if nx >= SLICEMAP_SIZE|| nz >= SLICEMAP_SIZE|| nx < 0|| nz < 0 do continue;

	                            	// this might not be right
	                            	// if we start on an obstacle then it may be a bit weird
	                            	
                                    // neighbour_pos := pos + {oc.x / DETAIL_MULTIPLIER, 0, oc.z / DETAIL_MULTIPLIER};
                                    neighbour_depth_val := _pixels[neighbour_idx].y;
	                            	is_void := neighbour_depth_val <= -999;
	                            	is_obstacle := abs(depth_val - neighbour_depth_val) > PLAYER_STEP_HEIGHT;

	                            	// y := cast(int) (_pixels[neighbour_idx].y*DETAIL_MULTIPLIER + 0.5 + SLICEMAP_SIZE/2);
	                            	// for yi := y; yi <= y+int(PLAYER_HEIGHT); yi += 1 {
	                            	// 	height_check_bit := cast(u128)1 << cast(u128)yi;
	                            	// 	is_obstacle |= g_current_negative_slicemap[z][x] & height_check_bit != 0;
	                            	// }

	                            	//round_to_int(_pixels[neighbour_idx].w) == 2
	                            	if is_void {
	                            		append(&layer.floor_plan, Floor_Vertex{pos, false, nx, nz});
	                            		break;
	                            	} else if is_obstacle {
	                            		append(&layer.floor_plan, Floor_Vertex{pos, true, nx, nz});
	                            		break;
	                            	} 
	                            }
	                        }

	                        if cast(int) layer_to_debug == layer_id && pathing_debug_state == .Vertex_Construction {
	                        	wb.end_render_pass(&pass);
	                        }
	                    }
                    }

		            if pathing_debug_state == .Vertices {
            			pass: wb.Render_Pass;
                        pass.camera = &g_editor_camera;
                        pass.color_buffers[0] = &debug_color_buffer;
                        pass.depth_buffer = &debug_depth_buffer;
                        wb.BEGIN_RENDER_PASS(&pass);
                        for layer, i in layers {
                        	if i != cast(int)layer_to_debug do continue;
                        	for vert, j in layer.floor_plan {
                        		// a := f32(j)/f32(len(layer.floor_plan));
                        		wb.draw_model(wb.g_models["cube_model"], vert.position, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], vert.is_obstacle ? {1,0,0,0.5} : {1,1,1,0.5});
                        	}
                        }
                    }
                    current_gen_state = .Object_Classification;
                    if !single_frame do return;
                }



                // Object classification
                if single_frame || current_gen_state == .Object_Classification {
                	layer_id := 0;
                    for layer in &layers {
                        if len(layer.cells) == 0 do continue;
                        defer layer_id += 1;

                		processed: [dynamic]int;
                		defer delete(processed);

                		_recurse_to_next_vert :: proc(current_vert: ^Floor_Vertex, processed: ^[dynamic]int, object: ^Layer_Object, floor_plan: ^[dynamic]Floor_Vertex) {
                			object_distance_threshold := f32(1) / DETAIL_MULTIPLIER + 0.01; // size of cell
                			for vert, i in floor_plan {
                				if slice.contains(processed[:], i) do continue;
                				if distance(Vector3{vert.position.x, 0, vert.position.z}, Vector3{current_vert.position.x, 0, current_vert.position.z}) > object_distance_threshold do continue;

                				append(&object.verts, vert);
                				append(processed, i);
                				_recurse_to_next_vert(&vert, processed, object, floor_plan);
                			}
                		}

                		// classify vertices into objects
                		for vert, i in &layer.floor_plan {
                			if slice.contains(processed[:], i) do continue;

                			obj: Layer_Object;
                			append(&obj.verts, vert);
                			append(&processed, i);
                			_recurse_to_next_vert(&vert, &processed, &obj, &layer.floor_plan);
                			append(&layer.objects, obj);
                		}

                        object_distance_threshold := f32(1) / DETAIL_MULTIPLIER + 0.01; // size of cell

                		// order the objects vertices
                		for obj in &layer.objects {
                			prev_vert := obj.verts[0];
                			append(&obj.ordered_verts, prev_vert);
                			unordered_remove(&obj.verts, 0);

                			for len(obj.verts) > 0 {
                				closest_idx := 0;
                				closest_vert: Floor_Vertex;
                                found := false;
                				for vert, i in obj.verts {
                					if i == 0 {
                						closest_vert = vert;
                						continue;
                					}

                					if distance(vert.position, prev_vert.position) < distance(closest_vert.position, prev_vert.position) {
                						closest_vert = vert;
                						closest_idx = i;
                                        found = true;
                					}
                				}

                                if found {
                    				append(&obj.ordered_verts, closest_vert);
                                }
	                			prev_vert = closest_vert;
	                			unordered_remove(&obj.verts, closest_idx);
                			}

                            for i := 0; i < len(obj.ordered_verts); i+=1 {
                                vert := obj.ordered_verts[i];

                                should_add := i == 0;

                                if i != 0 {
                                    orth_dist_to_prev := distance(v3_to_v2(vert.position), v3_to_v2(obj.ordered_verts[i-1].position));
                                    orth_dist_to_next := distance(v3_to_v2(vert.position), v3_to_v2(obj.ordered_verts[(i+1) % len(obj.ordered_verts)].position)); 

                                    close_to_prev := orth_dist_to_prev <= object_distance_threshold;
                                    close_to_next := orth_dist_to_next <= object_distance_threshold;

                                    should_add = close_to_prev && close_to_next;
                                }

                                if !should_add {
                                    ordered_remove(&obj.ordered_verts, i);
                                    i -= 1;
                                } else {
                                    append(&obj.verts, vert);
                                }
                            }
                		}

                    	if cast(int) layer_to_debug == layer_id && pathing_debug_state == .Layer_Objects {
                    		pass: wb.Render_Pass;
	                        pass.camera = &g_editor_camera;
	                        pass.color_buffers[0] = &debug_color_buffer;
	                        pass.depth_buffer = &debug_depth_buffer;
	                        wb.BEGIN_RENDER_PASS(&pass);

	                        for obj, i in layer.objects {
	                        	for vert, j in obj.verts {
	                        		colour := i>=len(colours) ? Vector4{1,0,0,0.3} : colours[i];
	                        		colour = {colour.x, colour.y, colour.z, f32(j)/f32(len(obj.verts)) + 0.1};
	                        		wb.draw_model(wb.g_models["cube_model"], vert.position, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], colour);
	                        	}
	                        }
                    	}

                    	// decimate unused vertices
                    	{
                    		for obj in &layer.objects {

                                if len(obj.verts) == 0 do continue;

                    			to_remove: [dynamic]int;
                    			defer delete(to_remove);
                    			
                    			current_vert := obj.verts[0];
                    			prev_dir: Vector3;
                    			prev_set := false;
                    			for vert, i in obj.verts {
                    				if i == 0 do continue;
                    				if !prev_set {
                    					prev_dir = norm(vert.position - current_vert.position);
                    					prev_set = true;
                    					continue;
                    				}

                    				cur_dir := norm(vert.position - current_vert.position);
                    				d := dot_2d(prev_dir, cur_dir);

                    				if d < 0.99999 { // different enough
                    					current_vert = obj.verts[i-1];
                    					prev_dir = norm(vert.position - current_vert.position);
                    				} else {
                    					append(&to_remove, i-1);
                    				}
                    			}
                    			if dot_2d(norm(obj.verts[0].position - obj.verts[len(obj.verts)-1].position), prev_dir) >= 0.99999 {
                    				append(&to_remove, len(obj.verts)-1);
                    			}

                    			clear(&obj.ordered_verts);
                    			for vert, i in obj.verts {
                    				if slice.contains(to_remove[:], i) do continue;
                    				append(&obj.ordered_verts, vert);
                    				if vert.is_obstacle do obj.is_obstacle = true;
                    			}
                    		}
                    		dot_2d :: proc(a,b: Vector3) -> f32 {
                    			return dot(norm(Vector3{a.x, 0, a.z}), norm(Vector3{b.x, 0, b.z}));
                    		}
                    	}

                    	if cast(int) layer_to_debug == layer_id && pathing_debug_state == .Layer_Objects_Decimated {
                    		pass: wb.Render_Pass;
	                        pass.camera = &g_editor_camera;
	                        pass.color_buffers[0] = &debug_color_buffer;
	                        pass.depth_buffer = &debug_depth_buffer;
	                        wb.BEGIN_RENDER_PASS(&pass);
	                        
	                        for obj, i in layer.objects {
	                        	for vert, j in obj.ordered_verts {
	                        		colour := i>=len(colours) ? Vector4{1,0,0,0.3} : colours[i];
	                        		colour = {colour.x, colour.y, colour.z, f32(j)/f32(len(obj.ordered_verts)) + 0.1};
	                        		wb.draw_model(wb.g_models["cube_model"], vert.position, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], colour);
	                        	}
	                        }
                    	}
                    }
                    current_gen_state = .Mesh_Generation;
                    if !single_frame do return;
                }



                if single_frame || current_gen_state == .Mesh_Generation {
                	// Nav Mesh Generation
                	layer_id := 0;
                    for layer in &layers {
                        if len(layer.cells) == 0 do continue;
                        defer layer_id += 1;

                        Notch_Vertex :: struct {
                        	position: Vector3,
                        	vm1, vm2: Vector3,
                        };

                        notch_vertices: [dynamic]Notch_Vertex;
                        defer delete(notch_vertices);

                        for obj in &layer.objects {
                        	for v0, j in obj.ordered_verts {
                        		v1 := obj.ordered_verts[(j+1) % len(obj.ordered_verts)];
                        		v2 := obj.ordered_verts[(j+2) % len(obj.ordered_verts)];

                        		a := (v0.x * (v1.y-v2.y) + v1.x * (v2.y-v0.y) + v2.x * (v0.y-v1.y)) / 2;

                                // TODO proper notches?
                        		if a > 0 || true {
                        			append(&notch_vertices, Notch_Vertex{v1.position, v0.position, v2.position});
                            	}
                            }
                        }

                        Near_Point :: struct {
                        	point: Vector3,
                        	distance: f32,
                            set: bool,
                        };

                        Portal :: struct {
                        	p0, p1: Vector3,
                        };
                        portals: [dynamic]Portal;

                        for nv, nv_id in notch_vertices {

                        	// AOI (Are of Interest) stuff
                			d1 := norm(nv.position - nv.vm1);
                			d2 := norm(nv.position - nv.vm2);
                			p1 := nv.position + {d1.x, 0, d1.z} * 50; 
                			p2 := nv.position + {d2.x, 0, d2.z} * 50;

                        	pass: wb.Render_Pass;
                    		if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
		                        pass.camera = &g_editor_camera;
		                        pass.color_buffers[0] = &debug_color_buffer;
		                        pass.depth_buffer = &debug_depth_buffer;
		                        wb.begin_render_pass(&pass);

		                        wb.draw_model(wb.g_models["cube_model"], nv.position, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {0,1,0,1});
		                        wb.draw_model(wb.g_models["cube_model"], nv.vm1, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {0.5,0.5,0.5,1});
		                        wb.draw_model(wb.g_models["cube_model"], nv.vm2, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {0.5,0.5,0.5,1});
		                        wb.im_line(render_context.editor_im_context, .World, nv.position, p1, {0,1,0,1});
                        		wb.im_line(render_context.editor_im_context, .World, nv.position, p2, {0,1,0,1});
                        		wb.im_line(render_context.editor_im_context, .World, p1, p2, {0,1,0,1});
		                    }

                        	nearest_point := Near_Point{ {}, 1000000000, false };
                        	for obj, j in &layer.objects {
	                        	for vert, i in obj.ordered_verts {

	                    			// get vert, skip if not in aoi
	                    			{
	                    				vert_in_aoi := point_in_triangle({vert.position.x, vert.position.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
	                        			if vert_in_aoi {
	                        				dist := distance(vert.position, nv.position);
	                        				if dist > 0.001 && dist < nearest_point.distance {
				                    			nearest_point.distance = dist;
				                    			nearest_point.point = vert.position;
                                                nearest_point.set = true;
				                    		}
			                    		}

			                    		if pathing_debug_state == .Portal_Creation && j == 0 && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
			                    			wb.draw_model(wb.g_models["cube_model"], vert.position, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], vert_in_aoi ? Vector4{0,1,0,1} : Vector4{1,0,0,1});
			                    		}
			                    	}

									// check against edge
									{
										edge0 := vert.position;
										edge1 := obj.ordered_verts[(i+1) % len(obj.ordered_verts)].position;
										
										if distance(edge0, nv.position) > 0.01 &&
										   distance(edge1, nv.position) > 0.01 {

											// project nv.position onto edge(edge0 and edge1)
											ap := nv.position - edge0;
											ab := edge1 - edge0;
											edge_projection := edge0 + dot(ap, ab) / dot(ab, ab) * ab;

											// does point fall in aoi?
											edge_projection_in_aoi := point_in_triangle({edge_projection.x, edge_projection.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
											projection_on_line := is_on_line(edge_projection, edge0, edge1);

                                            if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
                                                wb.im_line(render_context.editor_im_context, .World, edge0, edge1, {0,0,1,1});
                                            }

											// TODO figure out what is going on here
											if edge_projection_in_aoi && projection_on_line {
												dist := distance(edge_projection, nv.position);
												if dist > 0.001 && dist < nearest_point.distance {
													nearest_point.distance = dist;
													nearest_point.point = edge_projection;
                                                    nearest_point.set = true;

                                                    if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
                                                        wb.draw_model(wb.g_models["cube_model"], edge_projection, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {0,0,1,1});
                                                    }
												}
											} else {
												// dist to edge0
												edge0_dist := distance(edge0, nv.position);
												edge0_in_tri := point_in_triangle({edge0.x, edge0.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
												
												// dist to edge1
												edge1_dist := distance(edge1, nv.position);
												edge1_in_tri := point_in_triangle({edge0.x, edge0.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
												
												// dist to qr (project line vm1 onto edge)
												_qr, hitr := get_line_intersection(v3_to_v2(edge0), v3_to_v2(edge1), v3_to_v2(nv.position), v3_to_v2(nv.vm1));
												qr := Vector3{_qr.x, edge0.y, _qr.y}; // TODO figure out y
												qr_dist := distance(qr, nv.position);
												qr_in_tri := point_in_triangle({qr.x, qr.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
												if !hitr do qr_dist = 10000000;
												
												// dist to ql (project line vm2 onto edge)
												_ql, hitl := get_line_intersection(v3_to_v2(edge0), v3_to_v2(edge1), v3_to_v2(nv.position), v3_to_v2(nv.vm2));
												ql := Vector3{_ql.x, edge0.y, _ql.y};
												ql_dist := distance(ql, nv.position);
												ql_in_tri := point_in_triangle({ql.x, ql.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
												if !hitl do ql_dist = 10000000;

												if edge0_in_tri && is_smallest(edge0_dist, edge1_dist, qr_dist, ql_dist) {
													if edge0_dist > 0.001 && edge0_dist < nearest_point.distance {
														nearest_point.distance = edge0_dist;
														nearest_point.point = edge0;
                                                        nearest_point.set = true;

                                                        if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
                                                            wb.draw_model(wb.g_models["cube_model"], edge0, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {1,0,0,1});
                                                        }
													}
												} else if edge1_in_tri && is_smallest(edge1_dist, edge0_dist, qr_dist, ql_dist) {
													if edge1_dist > 0.001 && edge1_dist < nearest_point.distance {
														nearest_point.distance = edge1_dist;
														nearest_point.point = edge1;
                                                        nearest_point.set = true;

                                                        if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
                                                            wb.draw_model(wb.g_models["cube_model"], edge1, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {1,1,0,1});
                                                        }
													}
												} else if qr_in_tri && is_smallest(qr_dist, edge0_dist, edge1_dist, ql_dist) {
													dist := distance(qr, nv.position);
													if dist > 0.001 && dist < nearest_point.distance {
														nearest_point.distance = dist;
														nearest_point.point = qr;
                                                        nearest_point.set = true;

                                                        if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
                                                            wb.draw_model(wb.g_models["cube_model"], qr, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {1,0,1,1});
                                                        }
													}
												} else if ql_in_tri && is_smallest(ql_dist, edge0_dist, edge1_dist, qr_dist) {
													dist := distance(ql, nv.position);
													if dist > 0.001 && dist < nearest_point.distance {
														nearest_point.distance = dist;
														nearest_point.point = ql;
                                                        nearest_point.set = true;

                                                        if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && i == cast(int)debug_id2 && cast(int) layer_to_debug == layer_id {
                                                            wb.draw_model(wb.g_models["cube_model"], ql, {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], {0,1,1,1});
                                                        }
													}
												}
											}
										}
									}
	                        	}
                        	}

                        	// get nearest portal
                        	closest_portal: Portal;
                        	closest_portal_dist: f32 = 1000000000;
                        	portal_in_tri := false;
                            // TODO vertex-portal portal creation
                           //  	for portal in portals {
                           //  		ap := nv.position - portal.p0;
                        			// ab := portal.p0 - portal.p1;
                        			// portal_projection := portal.p0 + dot(ap, ab) / dot(ab, ab) * ab;
                        			// dist := distance(nv.position, portal_projection);
                        			// if dist < closest_portal_dist {
                        			// 	closest_portal = portal;
                        			// 	closest_portal_dist = dist;
                        			// }
                        			// portal_in_tri |= point_in_triangle({portal_projection.x, portal_projection.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
                        			// portal_in_tri |= point_in_triangle({portal.p0.x, portal.p0.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
                        			// portal_in_tri |= point_in_triangle({portal.p1.x, portal.p1.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z});
                           //  	}

                        	if portal_in_tri && closest_portal_dist < nearest_point.distance {
                    			// TODO merge portals
                    			if point_in_triangle({closest_portal.p0.x, closest_portal.p0.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z}) {
                    				append(&portals, Portal{ closest_portal.p0, nv.position });
                    				if nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
	                        			wb.im_line(render_context.editor_im_context, .World, closest_portal.p0, nv.position, {1,0,1,1});
	                        		}
                        		} else if point_in_triangle({closest_portal.p1.x, closest_portal.p1.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z}) {
                        			append(&portals, Portal{ closest_portal.p1, nv.position });
                        			if nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
	                        			wb.im_line(render_context.editor_im_context, .World, closest_portal.p1, nv.position, {1,0,1,1});
	                        		}
                        		} else {
                        			append(&portals, Portal{ closest_portal.p0, nv.position });
                        			append(&portals, Portal{ closest_portal.p1, nv.position });
                        			if nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
	                        			wb.im_line(render_context.editor_im_context, .World, closest_portal.p0, nv.position, {1,1,1,1});
	                        		}
	                        		if nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
	                        			wb.im_line(render_context.editor_im_context, .World, closest_portal.p1, nv.position, {1,1,1,1});
	                        		}
                        		}
                    		} else if nearest_point.set && point_in_triangle({nearest_point.point.x, nearest_point.point.z}, {p1.x, p1.z}, {nv.position.x, nv.position.z}, {p2.x, p2.z}) {
                        		append(&portals, Portal{ nearest_point.point, nv.position });
                        		if nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
                        			wb.im_line(render_context.editor_im_context, .World, nearest_point.point, nv.position, {1,0,0,1});
                        		}
                    		}

                    		if pathing_debug_state == .Portal_Creation && nv_id == cast(int)debug_id && cast(int) layer_to_debug == layer_id {
	                        	wb.draw_im_context(render_context.editor_im_context, &g_editor_camera);
	                        	wb.end_render_pass(&pass);
	                        }
                        }

                        if cast(int) layer_to_debug == layer_id && pathing_debug_state == .Portals {
                    		pass: wb.Render_Pass;
	                        pass.camera = &g_editor_camera;
	                        pass.color_buffers[0] = &debug_color_buffer;
	                        pass.depth_buffer = &debug_depth_buffer;
	                        wb.BEGIN_RENDER_PASS(&pass);
	                        
	                        for portal in portals {
                        		colour := Vector4{0,1,1,1};
                        		wb.im_line(render_context.editor_im_context, .World, portal.p0, portal.p1, colour);
	                        }

                            for obj in layer.objects {
                                prev_pos: Vector3;
                                for vert, i in obj.ordered_verts {
                                    if i == 0 {
                                        prev_pos = vert.position;
                                        continue;
                                    }
                                    wb.im_line(render_context.editor_im_context, .World, prev_pos, vert.position, Vector4{1,0,0,1});
                                    prev_pos = vert.position;
                                }
                                wb.im_line(render_context.editor_im_context, .World, prev_pos, obj.ordered_verts[0], Vector4{1,0,0,1});
                            }

	                        wb.draw_im_context(render_context.editor_im_context, &g_editor_camera);
                    	}

                        {
                            Line :: struct { p0,p1: Vector3, is_portal: bool };
                            layer_lines: [dynamic]Line;
                            defer delete(layer_lines);

                            for portal in portals {
                                append(&layer_lines, Line{ portal.p0, portal.p1, true });
                            }

                            for obj in layer.objects {
                                if len(obj.ordered_verts) == 0 do continue;
                                prev_pos: Vector3;
                                for vert, i in obj.ordered_verts {
                                    if i == 0 {
                                        prev_pos = vert.position;
                                        continue;
                                    }

                                    append(&layer_lines, Line{ prev_pos, vert.position, false });
                                    prev_pos = vert.position;
                                }

                                append(&layer_lines, Line{ prev_pos, obj.ordered_verts[0], false });
                            }

                            // This is very noisy to not be an O(n^2) operation
                            intersections: [dynamic]Vector3; defer delete(intersections);
                            _min, _max: Vector3;
                            for l0, i in layer_lines {
                                for l1, j in layer_lines {
                                    pt, intersects := get_line_intersection_3d(l0.p0, l0.p1, l1.p0, l1.p1);
                                    if !intersects do continue;

                                    contains := false;
                                    for inter in intersections {
                                        if distance(inter, pt) < 0.001 {
                                            contains = true;
                                            break;
                                        }
                                    }
                                    if contains do continue;

                                    append(&intersections, pt);

                                    if len(intersections) == 1 {
                                        _min = pt;
                                        _max = pt;
                                    }

                                    if pt.x < _min.x do _min.x = pt.x;
                                    if pt.z < _min.z do _min.z = pt.z;
                                    if pt.x > _max.x do _max.x = pt.x;
                                    if pt.z > _max.z do _max.z = pt.z;
                                }
                            }

                            // delaunay triangulation
                            triangles: [dynamic][3]Vector3; defer delete(triangles);

                            dx := _max.x - _min.x;
                            dy := _max.z - _min.z;
                            delta_max := max(dx, dy);
                            midx := (_min.x + _max.x) / 2;
                            midy := (_min.z + _max.z) / 2;

                            p1 := Vector3{midx - 2 * delta_max, 0, midy - delta_max};
                            p2 := Vector3{midx, 0, midy + 2 * delta_max};
                            p3 := Vector3{midx + 2 * delta_max, 0, midy - delta_max};
                            append(&triangles, [3]Vector3{p1, p2, p3});

                            for vert, did in intersections {
                                polygon: [dynamic][2]Vector3; defer delete(polygon);

                                to_remove: [dynamic]int; defer delete(to_remove);
                                for triangle, i in triangles {
                                    if circum_circle_contains(triangle, vert) {
                                        append(&to_remove, i);
                                        append(&polygon, [2]Vector3{ triangle[0], triangle[1] });
                                        append(&polygon, [2]Vector3{ triangle[1], triangle[2] });
                                        append(&polygon, [2]Vector3{ triangle[2], triangle[0] });
                                    }
                                }

                                for i := len(triangles)-1; i >= 0 ; i -= 1 {
                                    if !slice.contains(to_remove[:], i) do continue;
                                    unordered_remove(&triangles, i);
                                }

                                bad_edges: [dynamic]int; defer delete(bad_edges);
                                for edge0, i in polygon {
                                    for j := i+1; j < len(polygon); j+=1 {
                                        edge1 := polygon[j];
                                        if almost_equal(edge0, edge1) {
                                            append(&bad_edges, i);
                                            append(&bad_edges, j);
                                        }
                                    }
                                }

                                for edge, i in polygon {
                                    if slice.contains(bad_edges[:], i) do continue;
                                    append(&triangles, [3]Vector3 {
                                        edge[0], edge[1], vert,
                                    });
                                }
                            }

                            for i := len(triangles)-1; i >= 0; i-=1 {
                                tri := triangles[i];
                                extreme_in_super := false;
                                for vert in tri {
                                    extreme_in_super = distance(vert, p1) < 0.001;
                                    if extreme_in_super do break;
                                    extreme_in_super = distance(vert, p2) < 0.001;
                                    if extreme_in_super do break;
                                    extreme_in_super = distance(vert, p3) < 0.001;
                                    if extreme_in_super do break;
                                }
                                if extreme_in_super {
                                    unordered_remove(&triangles, i);
                                }
                            }

                            almost_equal :: proc(e0, e1: [2]Vector3) -> bool {
                                ret := distance(e0[0], e1[0]) <= 0.0001 && distance(e0[1], e1[1]) <= 0.0001;
                                ret |= distance(e0[1], e1[0]) <= 0.0001 && distance(e0[0], e1[1]) <= 0.0001;
                                return ret;
                            }

                            circum_circle_contains :: proc(tri: [3]Vector3, v: Vector3) -> bool {
                                norm2 :: proc(v: Vector3) -> f32 {
                                    return v.x * v.x + v.z * v.z;
                                }
                                dist2 :: proc(v0, v1: Vector3) -> f32 {
                                    dx := v0.x - v1.x;
                                    dy := v0.z - v1.z;
                                    return dx * dx + dy * dy;
                                }

                                a := tri[0];
                                b := tri[1];
                                c := tri[2];

                                ab := norm2(a);
                                cd := norm2(b);
                                ef := norm2(c);

                                ax := a.x;
                                ay := a.z;
                                bx := b.x;
                                by := b.z;
                                cx := c.x;
                                cy := c.z;

                                circum_x := (ab * (cy - by) + cd * (ay - cy) + ef * (by - ay)) / (ax * (cy - by) + bx * (ay - cy) + cx * (by - ay));
                                circum_y := (ab * (cx - bx) + cd * (ax - cx) + ef * (bx - ax)) / (ay * (cx - bx) + by * (ax - cx) + cy * (bx - ax));

                                circum := Vector3{circum_x / 2, 0, circum_y / 2};
                                circum_radius := dist2(a, circum);
                                dist := dist2(v, circum);
                                return dist <= circum_radius;
                            }

                            Cell :: struct {
                                points: [3]Vector3,
                                edge_passable: [3]bool,
                                adjacents: [3]int,
                            };
                            nav_graph: [dynamic]Cell;
                            for tri in triangles {
                                extreme_in_super := false;
                                for vert in tri {
                                    extreme_in_super = distance(vert, p1) < 0.001;
                                    if extreme_in_super do break;
                                    extreme_in_super = distance(vert, p2) < 0.001;
                                    if extreme_in_super do break;
                                    extreme_in_super = distance(vert, p3) < 0.001;
                                    if extreme_in_super do break;
                                }
                                if extreme_in_super do continue;

                                edge0_not_passable := false;
                                edge1_not_passable := false;
                                edge2_not_passable := false;
                                for line in layer_lines {
                                    if line.is_portal do continue;

                                    edge0_not_passable |= is_on_line(tri[0], line.p0, line.p1) && is_on_line(tri[1], line.p0, line.p1);
                                    edge1_not_passable |= is_on_line(tri[1], line.p0, line.p1) && is_on_line(tri[2], line.p0, line.p1);
                                    edge2_not_passable |= is_on_line(tri[2], line.p0, line.p1) && is_on_line(tri[0], line.p0, line.p1);
                                }

                                append(&nav_graph, Cell{tri, {!edge0_not_passable, !edge1_not_passable, !edge2_not_passable}, {-1,-1,-1}});
                            }

                            for cell0, i in &nav_graph {
                                neighbour_count := 0;
                                for cell1, j in nav_graph {
                                    if i == j do continue;

                                    is_neighbour := false;
                                    for pt0, p0i in cell0.points {
                                        edge0 := [2]Vector3{pt0, cell0.points[p0i%3]};
                                        for pt1, p1i in cell1.points {
                                            edge1 := [2]Vector3{pt1, cell1.points[p1i%3]};

                                            is_neighbour = almost_equal(edge0, edge1);
                                            
                                            if is_neighbour {
                                                cell0.adjacents[p0i] = j;
                                                break;
                                            }
                                        }
                                        if is_neighbour do break;
                                    }


                                } 
                            }

                            if cast(int) layer_to_debug == layer_id && pathing_debug_state == .NavMesh_Creation {
                                pass: wb.Render_Pass;
                                pass.camera = &g_editor_camera;
                                pass.color_buffers[0] = &debug_color_buffer;
                                pass.depth_buffer = &debug_depth_buffer;
                                wb.BEGIN_RENDER_PASS(&pass);

                                if cast(int) debug_id == 1 {
                                    for cell in nav_graph {
                                        wb.im_line(render_context.editor_im_context, .World, cell.points[0], cell.points[1], cell.edge_passable[0] ? {0,1,0,1} : {1,0,0,1});
                                        wb.im_line(render_context.editor_im_context, .World, cell.points[1], cell.points[2], cell.edge_passable[1] ? {0,1,0,1} : {1,0,0,1});
                                        wb.im_line(render_context.editor_im_context, .World, cell.points[2], cell.points[0], cell.edge_passable[2] ? {0,1,0,1} : {1,0,0,1});
                                    }
                                } else if cast(int) debug_id == 2 {
                                    for line in layer_lines {
                                        colour := line.is_portal ? Vector4{0,1,1,1} : Vector4{1,0,0,1};
                                        wb.im_line(render_context.editor_im_context, .World, line.p0, line.p1, colour);
                                    }
                                }

                                for pt, i in intersections {
                                    wb.draw_model(wb.g_models["cube_model"], pt, cast(int)debug_id==i ? {0.1,0.1,0.1} : {0.05, 0.05, 0.05}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], cast(int)debug_id==i ? {1,0,0,1} : {0,1,0,1});
                                }

                                wb.draw_im_context(render_context.editor_im_context, &g_editor_camera);
                            }
                        }
                	}

                	current_gen_state = .Coarse_Voxalization;
                	if !single_frame do return;
                }
            });
        // should_regen_nav_mesh = false;
    }
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

round_to_int :: proc(a: f32) -> int {
	return cast(int) (a + 0.5);
}

point_in_triangle :: proc(pt, v1, v2, v3: Vector2) -> bool {
    dX   := pt.x-v3.x;
    dY   := pt.y-v3.y;
    dX21 := v3.x-v2.x;
    dY12 := v2.y-v3.y;
    D    := dY12*(v1.x-v3.x) + dX21*(v1.y-v3.y);
    s    := dY12*dX + dX21*dY;
    t    := (v3.y-v1.y)*dX + (v1.x-v3.x)*dY;
    
    if D<0 do return s<=0 && t<=0 && s+t>=D;

    return s>=0 && t>=0 && s+t<=D;
}

get_line_intersection :: proc(p0, p1, p2, p3: Vector2) -> (Vector2, bool) {
	s1 := p1 - p0;
	s2 := p3 - p2;
	s := (-s1.y * (p0.x - p2.x) + s1.x * (p0.y - p2.y)) / (-s2.x * s1.y + s1.x * s2.y);
	t := (-s2.x * (p0.y - p2.y) + s2.y * (p0.x - p2.x)) / (-s2.x * s1.y + s1.x * s2.y);

	if s >= 0 && s <= 1 && t >= 0 && t <= 1 {
		return { p0.x + (t*s1.x), p0.y + (t*s1.y) }, true;
	}

	return {}, false;
}

get_line_intersection_3d :: proc(p1, p2, p3, p4: Vector3) -> (Vector3, bool) {
    EPS :: 0.0001;

    p13,p43,p21: Vector3;
    p13.x = p1.x - p3.x;
    p13.y = p1.y - p3.y;
    p13.z = p1.z - p3.z;
    p43.x = p4.x - p3.x;
    p43.y = p4.y - p3.y;
    p43.z = p4.z - p3.z;
    if abs(p43.x) < EPS && abs(p43.y) < EPS && abs(p43.z) < EPS do return {}, false;
    p21.x = p2.x - p1.x;
    p21.y = p2.y - p1.y;
    p21.z = p2.z - p1.z;
    if abs(p21.x) < EPS && abs(p21.y) < EPS && abs(p21.z) < EPS do return {}, false;

    d1343 := p13.x * p43.x + p13.y * p43.y + p13.z * p43.z;
    d4321 := p43.x * p21.x + p43.y * p21.y + p43.z * p21.z;
    d1321 := p13.x * p21.x + p13.y * p21.y + p13.z * p21.z;
    d4343 := p43.x * p43.x + p43.y * p43.y + p43.z * p43.z;
    d2121 := p21.x * p21.x + p21.y * p21.y + p21.z * p21.z;

    denom := d2121 * d4343 - d4321 * d4321;
    if abs(denom) < EPS do return {}, false;
    numer := d1343 * d4321 - d1321 * d4343;

    mua := numer / denom;
    mub := (d1343 + d4321 * mua) / d4343;

    if mua > 1 || mua < 0 || mub > 1 || mub < 0 do return {}, false;

    pa, pb: Vector3;
    pa.x = p1.x + mua * p21.x;
    pa.y = p1.y + mua * p21.y;
    pa.z = p1.z + mua * p21.z;

    pb.x = p3.x + mub * p43.x;
    pb.y = p3.y + mub * p43.y;
    pb.z = p3.z + mub * p43.z;

    if length(pa-pb) < 0.001 {
        return pa, true;
    }

    return {}, false;
}

is_on_line :: proc(pt, p0, p1: Vector3) -> bool {
	return abs(distance(p0, pt) + distance(p1, pt) - distance(p0, p1)) <= 0.01;
}

v3_to_v2 :: proc(v3: Vector3) -> Vector2 {
	return Vector2{v3.x, v3.z};
}

is_smallest :: proc(v1: f32, vals: ..f32) -> bool {
	for v in vals {
		if v < v1 do return false;
	}
	return true;
}