float cube_val(uint3 id, int i) 
{
	uint3 corner = (id + (uint3)vert_decals[i]);

	return DensityField.Load(int4( (int)corner.y, (int)corner.z, (int)corner.x, 0 )).x;
}

float3 cube_norm(float3 pos)
{
	float y = DensityField.Load(int4( (int)pos.y-1, (int)pos.z, (int)pos.x, 0)).x - DensityField.Load(int4( (int)pos.y+1, (int)pos.z, (int)pos.x, 0)).x;
	float z = DensityField.Load(int4( (int)pos.y, (int)pos.z-1, (int)pos.x, 0)).x - DensityField.Load(int4( (int)pos.y, (int)pos.z+1, (int)pos.x, 0)).x;
	float x = DensityField.Load(int4( (int)pos.y, (int)pos.z, (int)pos.x-1, 0)).x - DensityField.Load(int4( (int)pos.y, (int)pos.z, (int)pos.x+1, 0)).x;

	return normalize(float3(x,y,z));
}

float3 cube_pos(uint3 id, int i)
{
	float3 pos = (float3)id;
	return float3( stp*pos.x, stp*pos.y, stp*pos.z );
}

float3 vertex_interp(float3 p1, float v1, float3 p2, float v2) {
    if (abs(v1 - v2) > 0.00001) 
    {
        return p1 + (p2 - p1)/(v2 - v1)*(iso - v1);
    }
    else
    {
        return p1;
    } 
}

[numthreads(1,1,1)]
void CSMain(uint3 id : SV_DispatchThreadID)
{
	if (!(id.x <= 1 || id.y <= 1 || id.z <= 1 ||
		id.x >= (uint)(chunk_size.x-2) || id.y >= (uint)(chunk_size.y-2) || id.z >= (uint)(chunk_size.z-2))) {
		return;
	}

	int cube_index = 0;
    if (cube_val(id, 0) < iso) cube_index |= 1;
    if (cube_val(id, 1) < iso) cube_index |= 2;
    if (cube_val(id, 2) < iso) cube_index |= 4;
    if (cube_val(id, 3) < iso) cube_index |= 8;
    if (cube_val(id, 4) < iso) cube_index |= 16;
    if (cube_val(id, 5) < iso) cube_index |= 32;
    if (cube_val(id, 6) < iso) cube_index |= 64;
    if (cube_val(id, 7) < iso) cube_index |= 128;
    if (cube_index != 0 && cube_index != 255) 
    {
        int edge_val = edge_table[cube_index];
        if (edge_val != 0)
        {
            for (int i=0; tri_table[cube_index][i] != -1; i+=3) {
                int a0 = cornerIndexAFromEdge[tri_table[cube_index][i+0]];
                int b0 = cornerIndexBFromEdge[tri_table[cube_index][i+0]];

                int a1 = cornerIndexAFromEdge[tri_table[cube_index][i+1]];
                int b1 = cornerIndexBFromEdge[tri_table[cube_index][i+1]];

                int a2 = cornerIndexAFromEdge[tri_table[cube_index][i+2]];
                int b2 = cornerIndexBFromEdge[tri_table[cube_index][i+2]];

                Triangle tri;
                tri.verts[0].position = vertex_interp(cube_pos(id, a0), cube_val(id, a0), cube_pos(id, b0), cube_val(id, b0));
                // tri.verts[0].normal = cube_norm(pos1/stp);
                // tri.verts[0].colour = float4(1,1,1,1);
                // tri.verts[0].uv = float2(0,0);

                tri.verts[1].position = vertex_interp(cube_pos(id, a1), cube_val(id, a1), cube_pos(id, b1), cube_val(id, b1));
                // tri.verts[1].normal = cube_norm(pos2/stp);
                // tri.verts[1].colour = float4(1,1,1,1);
                // tri.verts[1].uv = float2(0,0);
                
                tri.verts[2].position = vertex_interp(cube_pos(id, a2), cube_val(id, a2), cube_pos(id, b2), cube_val(id, b2));
                // tri.verts[2].normal = cube_norm(pos3/stp);
                // tri.verts[2].colour = float4(1,1,1,1);
                // tri.verts[2].uv = float2(0,0);

                int orig = VerticesRW.IncrementCounter();
                VerticesRW[orig] = tri;
            }
        }
    }
}