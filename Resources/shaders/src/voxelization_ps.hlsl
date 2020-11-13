struct Pixel_Out {
	uint4 positive : SV_Target0;
	uint4 negative : SV_Target1;
};

Pixel_Out PS(Vertex_Out vertex) {
	float near;
	float far;
	float dist;

	if (direction == 0) {
		near = camera_position.y;
		far = camera_position.y - depth;
		dist = vertex.world_pos.y;
	}
	if (direction == 1) {
		near = camera_position.x;
		far = camera_position.x - depth;
		dist = vertex.world_pos.x;
	}
	if (direction == 2) {
		near = camera_position.z;
		far = camera_position.z - depth;
		dist = vertex.world_pos.z;
	}

	float percent_between = (dist - near) / (far - near);
	int cell = (int) (128.0 * (1-percent_between));

	uint4 val = uint4(0,0,0,0);
	if (cell > 0 || cell < 128) {
			 if (cell < 32 ) { val = uint4(1 << cell, 0, 0, 0); }
		else if (cell < 64 ) { val = uint4(0, 1 << cell - 32, 0, 0); }
		else if (cell < 96 ) { val = uint4(0, 0, 1 << cell - 64, 0); }
		else if (cell < 128) { val = uint4(0, 0, 0, 1 << cell - 96); }
	}

	Pixel_Out ret;
	ret.positive = uint4(0,0,0,0);
	ret.negative = uint4(0,0,0,0);
	float theta = cos(max_angle);
	float dt = dot(vertex.normal, float3(0,1,0));
	if (theta < dt) {
		ret.positive = val;
	} 
	else {
		ret.negative = val;
	}

    return ret;
}