{
    vertex_shader "lit_vertex"
    pixel_shader  "lit_pixel"

    properties [
        { name "base_color"        type Vector4 }
        { name "metallicness"      type Float   }
        { name "roughness"         type Float   }
        { name "ambient"           type Float   }
        { name "do_normal_mapping" type Int     }
    ]

    textures [
        { name "albedo_map" type Texture2D }
        { name "normal_map" type Texture2D }
        { name "skybox_map" type Cubemap   }

        { name "shadow_map0" type Texture2D }
        { name "shadow_map1" type Texture2D }
    ]
}