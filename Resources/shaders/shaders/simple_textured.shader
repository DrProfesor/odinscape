{
    vertex_shader "simple_vertex"
    pixel_shader  "simple_pixel_textured"

    properties [
        { name "base_color" type Vector4 }
    ]

    textures [
        { name "albedo_map" type Texture2D }
    ]
}
