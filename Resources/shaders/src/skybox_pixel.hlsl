SamplerState main_texture_sampler;

float4 PS(Vertex_Out vertex) : SV_TARGET {
    float4 albedo = albedo_map.Sample(main_texture_sampler, vertex.tex_coord);
    return albedo;
}
