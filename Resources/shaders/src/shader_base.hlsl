struct Vertex_In {
    float4 position     : SV_POSITION;
    float3 tex_coord    : TEXCOORD;
    float4 color        : COLOR;
    float3 normal       : NORMAL;
    float3 tangent      : TANGENT;
    float3 bitangent    : BITANGENT;
    uint4  bone_indices : BLENDINDICES;
    float4 bone_weights : BLENDWEIGHT;
};

struct Vertex_Out {
    float4 position  : SV_POSITION;
    float3 tex_coord : TEXCOORD;
    float4 color     : COLOR;
    float3 normal    : NORMAL;
    float3 tangent   : TANGENT;
    float3 bitangent : BITANGENT;
    float3 world_pos : WORLDPOS;
    matrix<float, 3, 3> tbn : TBN;
};

cbuffer CBUFFER_CAMERA : register(b0) {
    float3 camera_position;
    row_major matrix view;
    row_major matrix proj;
    float time;
}

cbuffer CBUFFER_SPECIFIC : register(b1) {
    row_major matrix model;
    float4 mesh_color;
};

// note(josh): Material cbuffer is slot b2