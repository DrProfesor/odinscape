#define SLICEMAP_SIZE 128

SamplerState main_texture_sampler;

int PS(Vertex_Out vertex) : SV_TARGET {
	// cell_pos := (Vector3{f32(x)-SLICEMAP_SIZE/2, f32(y) - SLICEMAP_DEPTH/2, f32(z)-SLICEMAP_SIZE/2} + {0.5,-0.5,0.5}) / DETAIL_MULTIPLIER;
	int x = (int) (vertex.position.x + SLICEMAP_SIZE/2);
	int z = (int) (vertex.position.z + SLICEMAP_SIZE/2);
	int4 pixel = cutting_shape.Sample(main_texture_sampler, float2(x,z));

	if (pixel.x != 1) {
		return 0;
	}
	
	return 1;
}