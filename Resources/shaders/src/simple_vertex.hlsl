Vertex_Out VS(
        float4 inPos       : POSITION,
        float3 inTexCoord  : TEXCOORD,
        float4 inColor     : COLOR,
        float3 inNormal    : NORMAL,
        float3 inTangent   : TANGENT,
        float3 inBitangent : BITANGENT) {

    matrix mvp = mul(model, mul(view, proj));
    Vertex_Out vertex;
    vertex.position  = mul(inPos, mvp);
    vertex.color     = inColor;
    vertex.tex_coord = inTexCoord;
    vertex.world_pos = mul(inPos, model).xyz;

    // todo(josh): fix normals for non-uniformly scaled objects
    float3 T = normalize(mul(float4(inTangent,   0), model).xyz);
    float3 B = normalize(mul(float4(inBitangent, 0), model).xyz);
    float3 N = normalize(mul(float4(inNormal,    0), model).xyz);
    vertex.tbn = matrix<float, 3, 3>(T, B, N);

    vertex.normal    = N;
    vertex.tangent   = T;
    vertex.bitangent = B;

    return vertex;
}