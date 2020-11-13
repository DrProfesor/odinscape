{
	vertex_shader "lit_vertex"
    pixel_shader  "voxel_depthmap_extractor_ps"

	properties [
	]

	textures [
		{ name "cutting_shape" type Texture2D }
	]
}