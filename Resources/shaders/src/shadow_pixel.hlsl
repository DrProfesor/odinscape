float4 PS(Vertex_Out vertex) : SV_TARGET {
    float v = vertex.position.z / vertex.position.w;
    return float4(v, v, v, 1.0); // todo(josh): ew. the shadow map shouldn't be 4 components, that's silly.
}