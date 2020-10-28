#define MAX_LIGHTS 16 // :MaxLights
#define NUM_SHADOW_MAPS 3 // :NumShadowMaps
cbuffer CBUFFER_LIGHTING : register(b4) {
    float4 point_light_positions[MAX_LIGHTS];
    float4 point_light_colors[MAX_LIGHTS];
    float4 point_light_intensities[MAX_LIGHTS];
    int    num_point_lights;
    float3 sun_direction;
    float3 sun_color;
    float  sun_intensity;
    row_major matrix sun_matrices[NUM_SHADOW_MAPS];
    float4 cascade_distances;
    float2 shadow_map_dimensions;
};

SamplerState main_texture_sampler;

#define PI 3.14159265359

float3 fresnel_schlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float distribution_ggx(float3 N, float3 H, float roughness) {
    float a      = roughness*roughness;
    float NdotH  = max(dot(N, H), 0.001);
    float NdotH2 = NdotH*NdotH;

    float num   = a;
    float denom = (NdotH2 * (a - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

float geometry_schlick_ggx(float NdotV, float roughness, int analytic) {
    // todo(josh): (roughness + 1) should only be used for analytic light sources, not IBL
    // "if applied to image-based lighting, the results at glancing angles will be much too dark"
    // page 3
    // https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf

    float k;
    if (analytic == 1) {
        k = pow((roughness + 1.0), 2.0) * 0.125;
    }
    else {
        k = pow(roughness, 2.0) * 0.5;
    }

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}
float geometry_smith(float3 N, float3 V, float3 L, float roughness, int analytic) {
    float NdotV = max(dot(N, V), 0.001);
    float NdotL = max(dot(N, L), 0.001);
    float ggx2  = geometry_schlick_ggx(NdotV, roughness, analytic);
    float ggx1  = geometry_schlick_ggx(NdotL, roughness, analytic);

    return ggx1 * ggx2;
}

float3 calculate_light(float3 albedo, float metallic, float roughness, float3 N, float3 V, float3 L, float3 radiance, int analytic) {
    float3 H = normalize(V + L);

    // todo(josh): no need to do this for each light, should be constant for a given draw call
    float3 F0 = float3(0.04, 0.04, 0.04);
    F0 = lerp(F0, albedo, metallic);

    // cook-torrance brdf
    float  NDF = distribution_ggx(N, H, roughness);
    float  G   = geometry_smith(N, V, L, roughness, analytic);
    float3 F   = fresnel_schlick(saturate(dot(H, V)), F0);

    float3 kS = F;
    float3 kD = float3(1.0, 1.0, 1.0) - kS;
    kD *= 1.0 - metallic;

    float3 numerator  = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.001) * max(dot(N, L), 0.001);
    float3 specular   = numerator / max(denominator, 0.001);

    // add to outgoing radiance Lo
    float NdotL = max(dot(N, L), 0.001);
    return (kD * albedo / PI + specular) * radiance * NdotL;
}

float calculate_shadow(Texture2D shadow_map_texture, row_major matrix sun_matrix, float3 world_pos, float3 N) {
    float4 frag_position_light_space = mul(float4(world_pos, 1.0), sun_matrix);
    float3 proj_coords = frag_position_light_space.xyz / frag_position_light_space.w; // todo(josh): check for divide by zero?
    proj_coords.xy = proj_coords.xy * 0.5 + 0.5;
    proj_coords.y = 1.0 - proj_coords.y;
    if (proj_coords.z > 1.0) {
        proj_coords.z = 1.0;
    }

    float dot_to_sun = clamp(dot(N, -sun_direction), 0, 1);
    float bias = max(0.01 * (1.0 - dot_to_sun), 0.001);
    // float bias = 0.01;

    float2 texel_size = 1.0 / shadow_map_dimensions.x;
    float shadow = 0;
#if 1
    shadow = shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy).r + bias < proj_coords.z ? 1.0 : 0.0;
#elif 0
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2(-1, -1) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2( 0, -1) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2( 1, -1) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2(-1,  0) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2( 0,  0) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2( 1,  0) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2(-1,  1) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2( 0,  1) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow += shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2( 1,  1) * texel_size).r + bias < proj_coords.z ? 1.0 : 0.0;
    shadow /= 9.0;
#else
    for (int x = -2; x <= 2; x += 1) {
        for (int y = -2; y <= 2; y += 1) {
            float pcf_depth = shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy + float2(x, y) * texel_size).r;
            shadow += pcf_depth + bias < proj_coords.z ? 1.0 : 0.0;
        }
    }
    shadow /= 25.0;
#endif
    return shadow;
}

/*
float3 decal(Vertex_Out vertex) {
    float4 frag_position_light_space = mul(float4(vertex.world_pos, 1.0), sun_matrix);
    float3 proj_coords = frag_position_light_space.xyz / frag_position_light_space.w; // todo(josh): check for divide by zero?
    proj_coords.xy = proj_coords.xy * 0.5 + 0.5;
    if (proj_coords.z > 1.0) {
        proj_coords.z = 1.0;
    }

    float3 color = shadow_map_texture.Sample(main_texture_sampler, proj_coords.xy).rgb;
    return color;
}
*/

float4 PS(Vertex_Out vertex) : SV_TARGET {
    float4 albedo = albedo_map.Sample(main_texture_sampler, vertex.tex_coord.xy) * base_color;

    // todo(josh): fix normals for non-uniformly scaled objects
    float3 N = normalize(vertex.normal);

    if (do_normal_mapping == 1) {
        N = normal_map.Sample(main_texture_sampler, vertex.tex_coord.xy).xyz;
        N = N * 2.0 - 1.0;
        N = normalize(mul(N, vertex.tbn));
    }
    // return float4(N * 0.5 + 0.5, 1.0);

    float3 V = normalize(camera_position - vertex.world_pos);

    float3 color = albedo.xyz * ambient * base_color.xyz;
    for (int i = 0; i < num_point_lights; i++) {
        float3 light_position  = point_light_positions[i].xyz;
        float3 light_color     = point_light_colors[i].xyz;
        float  light_intensity = point_light_intensities[i].x;

        float3 offset_to_light = light_position - vertex.world_pos;
        float distance_to_light = length(offset_to_light);
        float attenuation = 1.0 / (distance_to_light * distance_to_light);
        float3 L = normalize(offset_to_light);
        color += calculate_light(albedo.xyz, metallicness, roughness, N, V, L, light_color * light_intensity * attenuation, 1);
    }

    float3 sun_radiance = calculate_light(albedo.xyz, metallicness, roughness, N, V, -sun_direction, sun_color * sun_intensity, 1);

    float dist = distance(camera_position, vertex.world_pos);
    float shadow = 1.0;
         if (dist > cascade_distances.z) { shadow = 1; }
    else if (dist > cascade_distances.y) { shadow = 1.0 - calculate_shadow(shadow_map1, sun_matrices[1], vertex.world_pos, N); }
    else if (dist > cascade_distances.x) { shadow = 1.0 - calculate_shadow(shadow_map0, sun_matrices[0], vertex.world_pos, N); }
    color += sun_radiance * shadow;

    //      if (dist > cascade_distances.z) { color += float3(0.2, 0, 0); }
    // else if (dist > cascade_distances.y) { color += float3(0, 0.2, 0); }
    // else if (dist > cascade_distances.x) { color += float3(0, 0, 0.2); }

    float3 reflected_direction = normalize(reflect(-V, N));
    float3 skybox_color = skybox_map.Sample(main_texture_sampler, reflected_direction).xyz;
    color += calculate_light(albedo.xyz, metallicness, roughness, N, V, reflected_direction, skybox_color, 0);

    // tone mapping
    const float exposure = 1;
    color = float3(1.0, 1.0, 1.0) - exp(-color * exposure);

    return float4(color, albedo.a) * vertex.color * mesh_color;
}