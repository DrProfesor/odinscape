{
	vertex_shader "lit_vertex"
    pixel_shader  "voxel_depthmap_extractor_ps"

	properties [
		{ name "slicemap_size" type Float }
		{ name "cell_center_offset" type Float }
		{ name "detail_multiplier" type Float }
	]

	textures [
		{ name "cutting_shape" type Texture2D tex_prim_type "uint4" }
	]
}