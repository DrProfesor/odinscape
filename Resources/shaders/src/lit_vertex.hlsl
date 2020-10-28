Vertex_Out VS(Vertex_In vertex) {

    float4 skinned_position = float4(0, 0, 0, 0);
    // todo(josh): normals, tangents, bitangents?
    if (do_animation == 1) {
        skinned_position += mul(vertex.position, bone_transforms[vertex.bone_indices.x]) * vertex.bone_weights.x;
        skinned_position += mul(vertex.position, bone_transforms[vertex.bone_indices.y]) * vertex.bone_weights.y;
        skinned_position += mul(vertex.position, bone_transforms[vertex.bone_indices.z]) * vertex.bone_weights.z;
        skinned_position += mul(vertex.position, bone_transforms[vertex.bone_indices.w]) * vertex.bone_weights.w;
    }
    else {
        skinned_position = vertex.position;
    }

    matrix mvp = mul(model, mul(view, proj));
    Vertex_Out vertex_out;
    vertex_out.position  = mul(skinned_position, mvp);
    vertex_out.color     = vertex.color;
    vertex_out.tex_coord = vertex.tex_coord;
    vertex_out.world_pos = mul(skinned_position, model).xyz;

    // todo(josh): fix normals for non-uniformly scaled objects
    float3 T = normalize(mul(float4(vertex.tangent,   0), model).xyz);
    float3 B = normalize(mul(float4(vertex.bitangent, 0), model).xyz);
    float3 N = normalize(mul(float4(vertex.normal,    0), model).xyz);
    vertex_out.tbn = matrix<float, 3, 3>(T, B, N);

    vertex_out.normal    = N;
    vertex_out.tangent   = T;
    vertex_out.bitangent = B;

    return vertex_out;
}