float PS(Vertex_Out vertex) : SV_TARGET {
	// cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / DETAIL_MULTIPLIER;
	// int x = (int) vertex.world_pos.x*2 - 0.5 + SLICEMAP_SIZE/2;
	// int z = (int) vertex.world_pos.z*2 - 0.5 + SLICEMAP_SIZE/2;
	
	uint4 pixel = cutting_shape.Load(int3(vertex.position.xy, 0));
	if (pixel.x == 0) {
		discard;
	}

	float3 o = float3((float)pixel.y-slicemap_size/2, (float)pixel.z-slicemap_size/2, (float)pixel.w-slicemap_size/2);
	float3 a = o - float3(cell_center_offset,-cell_center_offset,cell_center_offset);
	float3 b = a / float3(detail_multiplier,detail_multiplier,detail_multiplier);
	float4 cell_pos = float4(b.xyz, 1.0);
	matrix mvp = mul(model, mul(view, proj));
	float4 screen_space_cell_pos = mul(cell_pos, mvp);
	
	float depth = (-vertex.position.z / vertex.position.w) + 0.001;
	float cell_depth = -screen_space_cell_pos.z / screen_space_cell_pos.w;

	if (depth < cell_depth) {
		discard;
	}

	float theta = cos(45.0);
	float dt = dot(vertex.normal, float3(0,1,0));
	if (theta > dt) {
		discard;
	} 

	return (float)((int)(depth*100)) / 100;
}