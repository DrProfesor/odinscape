{
	vertex_shader "lit_vertex"
    pixel_shader  "voxelization_ps"

	properties [
		{ name "depth" type Int }
		{ name "max_angle" type Float}
	]

	textures [
	]
}