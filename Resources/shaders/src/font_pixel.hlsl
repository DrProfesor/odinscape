SamplerState main_texture_sampler;

float4 PS(Vertex_Out vertex) : SV_TARGET {
    float value = albedo_map.Sample(main_texture_sampler, vertex.tex_coord.xy).r;
    return float4(1.0, 1.0, 1.0, value) * vertex.color;
}