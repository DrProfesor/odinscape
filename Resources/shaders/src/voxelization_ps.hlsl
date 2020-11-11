struct Pixel_Out {
	uint4 positive : SV_Target0;
	// float4 negative : SV_Target1;
};

Pixel_Out PS(Vertex_Out vertex) {
	float near = camera_position.y;
	float far = camera_position.y - depth;

	float percent_between = (vertex.world_pos.y - near) / (far - near);
	int cell = (int) (128.0 * (1-percent_between));

	uint4 val = uint4(0,0,0,0);
	if (cell > 0 || cell < 128) {
			 if (cell < 32 ) { val = uint4(1 << cell, 0, 0, 0); }
		else if (cell < 64 ) { val = uint4(0, 1 << cell - 32, 0, 0); }
		else if (cell < 96 ) { val = uint4(0, 0, 1 << cell - 64, 0); }
		else if (cell < 128) { val = uint4(0, 0, 0, 1 << cell - 96); }
	}

	Pixel_Out ret;
	ret.positive = float4(0,0,0,0);
	if (cos(max_angle) < dot(vertex.normal, float3(0,1,0))) {
		ret.positive = val;
	} 
	// else {
	// 	ret.negative = val;
	// }

    return ret;
}