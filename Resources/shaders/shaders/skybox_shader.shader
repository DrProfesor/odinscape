{
    vertex_shader "skybox_vertex"
    pixel_shader  "skybox_pixel"

    properties [
    ]

    textures [
        { name "albedo_map" type Cubemap }
    ]
}
