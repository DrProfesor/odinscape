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
g_current_floorplan: [SLICEMAP_SIZE][SLICEMAP_SIZE]u8;

colours : []Vector4 = { {1,0,0,0.5}, {1,0.5,0.1,0.5}, {0,1,0,0.5}, {0.1,1,0.5,0.5}, {0,1,1,0.5}, {0,0.5,1,0.5}, {0.2,0,1,0.5}, {0.6,0,1,0.5}, {1,0,1,0.5} };
orthogonal_cells := [4]Vector3{{-1,0,0}, {1,0,0}, {0,0,1}, {0,0,-1}};

Layer :: struct { 
	floor_plan: [dynamic]Floor_Vertex,
	objects: [dynamic]Layer_Object,
	cells: [dynamic]u64,  
}
Layer_Object :: struct {
	ordered_verts: [dynamic]Floor_Vertex,
}
Floor_Vertex :: struct {
	position: Vector3,
	is_obstacle: bool,
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
	Layer_Refinement
}

update_navmesh :: proc() {
}

current_gen_state: Gen_State;
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
                if current_gen_state == .Coarse_Voxalization {
					directions := [3]Vector3{{0,1,0}, {1,0,0}, {0,0,-1}};
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
                                z := j%SLICEMAP_SIZE;
                                x := j/SLICEMAP_SIZE;
                                g_current_slicemap[x][z] = pi_pixels[j];
                                g_current_negative_slicemap[x][z] = ni_pixels[j];
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
                                x := SLICEMAP_SIZE - j%SLICEMAP_SIZE;
                                y := j/SLICEMAP_SIZE;
                                yb := u128(1) << u128(SLICEMAP_DEPTH-1-y);
                                for z in 0..<SLICEMAP_DEPTH {
                                    if ni_pixels[j] & (u128(1) << u128(z)) != 0 {
                                        g_current_negative_slicemap[z][x] |= yb;
                                    }
                                }
                            }
                        }
                    }

                    current_gen_state = .Layer_Extraction;
                    return;
                }

                

                // Layer extraction
                if current_gen_state == .Layer_Extraction {
                	layers = {};
                    cells: map[u64]int;
                    defer delete(cells);
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
                                	if g_current_negative_slicemap[z][x] & height_check_bit != 0 ||
                                	   g_current_slicemap[z][x] & height_check_bit != 0 {
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
                    return;
                }

                get_cell_id :: proc(x,y,z: int) -> u64 {
                    return transmute(u64) (((cast(u64)i16(x)) << 48) | ((cast(u64)i16(z)) << 32) | ((cast(u64)i16(y)) << 16));
                }

                // Layer refinement
                if current_gen_state == .Layer_Refinement {
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
                                cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, SLICEMAP_SIZE-f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / {DETAIL_MULTIPLIER,DETAIL_MULTIPLIER,DETAIL_MULTIPLIER};
                                wb.draw_model(wb.g_models["cube_model"], cell_pos, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], l>=len(colours) ? {0.3,0,0,0.5} : colours[l]);
                            }
                            l+=1;
                        }
                    }

                    for layer, layer_id in &layers {
                        if len(layer.cells) == 0 do continue;

                        // Create the layers cutting shape
                        {
	                        g_cutting_shape_data = {};
	                        for cell in layer.cells {
	                            x := u32(i16(cell >> 48));
	                            z := u32(i16(cell >> 32));
	                            y := u32(i16(cell >> 16));
	                            cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, SLICEMAP_SIZE-f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / {DETAIL_MULTIPLIER,DETAIL_MULTIPLIER,DETAIL_MULTIPLIER};

	                            j := x + (z * SLICEMAP_SIZE);
	                            g_cutting_shape_data[j] = Vector4{1,cell_pos.x,cell_pos.y,cell_pos.z};
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
	                        pass_desc.clear_color = {-1000,0,0,0};
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

	                        g_current_floorplan = {};
	                        _pixels := transmute([]Vector4)pixels;
	                        max := len(pixels)/16;
	                        for i in 0..<max {
	                            depth_val := _pixels[i].y;
	                            if depth_val <= -999 do continue; // min value set from above this is empty space for this layer
	                            x := i%SLICEMAP_SIZE;
	                        	z := i/SLICEMAP_SIZE;
	                        	
	                        	pos := Vector3{_pixels[i].x,_pixels[i].y,_pixels[i].z};
	                        	if g_current_floorplan[x][z] != 0 {
		                        	wb.draw_model(wb.g_models["cube_model"], pos, {0.8,0.8,0.8}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], g_current_floorplan[x][z] == 1 ? Vector4{0,1,0,1} : Vector4{0,0,1,1});
		                        }
	                        	
	                        	// if g_current_floorplan[x][z] != 0 do continue; // already an obstacle

	                            for oc in orthogonal_cells {
	                            	nx := x + int(oc.x);
	                            	nz := z + int(oc.z);
	                            	neighbour_idx := nx + nz*SLICEMAP_SIZE;
	                            	if neighbour_idx >= max do continue;
	                            	if neighbour_idx <  0   do continue;
	                            	// this might not be right
	                            	// if we start on an obstacle then it may be a bit weird
	                            	neighbour_pos := Vector3{_pixels[neighbour_idx].x,_pixels[neighbour_idx].y,_pixels[neighbour_idx].z};
	                            	neighbour_depth_val := neighbour_pos.y;
	                            	is_obstacle := abs(depth_val - neighbour_depth_val) > PLAYER_STEP_HEIGHT;
	                            	is_void := neighbour_depth_val <= -999;

	                            	colour := Vector4{0.5,0.5,0.5,1};
	                            	if nx < SLICEMAP_SIZE && nz < SLICEMAP_SIZE && nx >= 0 && nz >= 0 {
		                            	if is_void {
		                            		g_current_floorplan[nx][nz] = 1;
		                            		append(&layer.floor_plan, Floor_Vertex{neighbour_pos, false});
		                            		colour = {1,0,0,1};
		                            		if pathing_debug_state == .Vertex_Construction {
					                            wb.draw_model(wb.g_models["cube_model"], (pos + neighbour_pos) / 2, {0.1,0.1,0.1}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], colour);
					                        }
		                            	} else if is_obstacle {
		                            		g_current_floorplan[nx][nz] = 2;
		                            		append(&layer.floor_plan, Floor_Vertex{neighbour_pos, true});
		                            		colour = {0,1,0,1};
		                            		if pathing_debug_state == .Vertex_Construction {
					                            wb.draw_model(wb.g_models["cube_model"], (pos + neighbour_pos) / 2, {0.1,0.1,0.1}, Quaternion(1), wb.g_materials["simple_rgba_mtl"], colour);
					                        }
		                            	}
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
                        	for vert in layer.floor_plan {
                        		wb.draw_model(wb.g_models["cube_model"], vert.position, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], i>=len(colours) ? {0.5,0,0,0.5} : colours[i]);
                        	}
                        }
                    }
                    current_gen_state = .Coarse_Voxalization;
                    return;
                }

                // Nav Mesh Generation
                {
                	// Object classification
                	object_distance_threshold := 1 / DETAIL_MULTIPLIER; // size of cell
                	for layer, layer_id in &layers {
                		// apply gift wrapping algorithm 
                		current_layer_object: Layer_Object;
                		processing_vert: ^Floor_Vertex = &layer.floor_plan[0];
                		processing_vert_idx := 0;
                		processed: [dynamic]int;
                    	for processing_vert != nil {
                    		log_info("");
                    		connected := false;
                    		for vert, i in &layer.floor_plan {
                    			if &vert == processing_vert do continue;
                    			if distance(vert.position, processing_vert.position) > 1.1 do continue;
                    			if slice.contains(processed[:], i) do continue;

                    			processing_vert = &vert;
                    			connected = true;
                    			append(&processed, processing_vert_idx);
                    			append(&current_layer_object.ordered_verts, processing_vert^);
                    		}

                    		if !connected {
                    			append(&layer.objects, current_layer_object);
                    			clear(&current_layer_object.ordered_verts);
                    		}
                    	}

                    	append(&layer.objects, current_layer_object);

                    	if cast(int) layer_to_debug == layer_id && pathing_debug_state == .Layer_Objects {
                    		pass: wb.Render_Pass;
	                        pass.camera = &g_editor_camera;
	                        pass.color_buffers[0] = &debug_color_buffer;
	                        pass.depth_buffer = &debug_depth_buffer;
	                        wb.BEGIN_RENDER_PASS(&pass);

	                        for obj, i in layer.objects {
	                        	for vert in obj.ordered_verts {
	                        		wb.draw_model(wb.g_models["cube_model"], vert.position, {0.9,0.9,0.9}/DETAIL_MULTIPLIER, Quaternion(1), wb.g_materials["simple_rgba_mtl"], i>=len(colours) ? {0.5,0,0,0.5} : colours[i]);
	                        	}
	                        }
                    	}

                    	// apply Ramer–Douglas–Peucker algorithm to decimate unnecessary vertices
                    }


                    // Convexity relaxation

                    // Merging layers
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