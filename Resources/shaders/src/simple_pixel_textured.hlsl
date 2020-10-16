SamplerState main_texture_sampler;

float4 PS(Vertex_Out vertex) : SV_TARGET {
    float4 albedo = albedo_map.Sample(main_texture_sampler, vertex.tex_coord.xy);

    // todo(josh): should we do exposure for simple stuff? I expect not
    // color = float3(1.0, 1.0, 1.0) - exp(-color * 1);

    return albedo * vertex.color * base_color * mesh_color;
}