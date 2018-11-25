package main

using import    "core:math"
using import    "core:fmt"
      import    "core:os"
      import    "core:strings"
      import    "shared:workbench/wbml"
      import wb "shared:workbench"

SCENE_DIRECTORY :: "resources/scenes/";
RESOURCES :: "resources/";

Asset_Type :: enum {
	Model,
	Texture,
}

scene_init :: proc(scene_file : string) {
	scene_data, ok := os.read_entire_file(tprint(SCENE_DIRECTORY, scene_file, ".scene"));
	assert(ok, tprint("Couldn't find ", SCENE_DIRECTORY, scene_file, ".scene"));
	defer delete(scene_data);

	scene := wbml.deserialize(Scene, string(scene_data));

	for _, i in 0 .. len(scene.manifest.entries)-1 {

		entry := new_clone(scene.manifest.entries[i]);
		
		switch entry.asset_type {
			case Asset_Type.Model: {
				if ok {
					current := loaded_textures[entry.id];
					current.count += 1;
					loaded_textures[entry.id] = current;
				} else {
					wb.catalog_subscribe(tprint(RESOURCES, entry.path), entry, 
						proc(entry: ^Manifest_Entry, entry_data: []u8) {
							_, ok := loaded_models[entry.id];
							if ok {
								// TODO(jake): hotloading
							} else {
								// TODO (jake): don't do this, use load_model_from_memory
								path := strings.new_cstring(tprint(RESOURCES, entry.path));
								model := wb.buffer_model(wb.load_model_from_file(path));
								loaded_models[entry.id] = Model_Asset{model, 1};
								delete(entry_data);
							}
						});
				}
				break;
			}
			case Asset_Type.Texture: {
				if ok {
					current := loaded_textures[entry.id];
					current.count += 1;
					loaded_textures[entry.id] = current;
				} else {
					wb.catalog_subscribe(tprint(RESOURCES, entry.path), entry, 
						proc(entry: ^Manifest_Entry, entry_data: []u8) {
							_, ok := loaded_textures[entry.id];
							if ok {
								// TODO(jake): hotloading
							} else {
								texture := wb.load_texture(entry_data);
								loaded_textures[entry.id] = Texture_Asset{texture, 1};
								delete(entry_data);
							}
						});
				}
				break;
			}
		}
	}
}

scene_update :: proc() {

}

scene_end :: proc() {
	// TODO check existing and delete if no scenes are using
}

//
// Models
//
loaded_models : map[string]Model_Asset;

Model_Asset :: struct {
	asset: wb.Model,
	count: int,
}

get_model :: proc(id: string) -> wb.Model {
	model, ok := loaded_models[id];
	assert(ok, tprint("Could not find model asset with id:", id));
	return model.asset;
}

//
// Textures
//
loaded_textures : map[string]Texture_Asset;

Texture_Asset :: struct {
	asset: wb.Texture,
	count: int,
}

get_texture :: proc(id: string) -> wb.Texture {
	texture, ok := loaded_textures[id];
	assert(ok, tprint("Could not find texture asset with id:", id));
	return texture.asset;
}


//
// Scene Data
//
Manifest_Entry :: struct {
	id: string,
	path: string,
	asset_type: Asset_Type,
}

Entity_Manifest :: struct {
	entries: [dynamic]Manifest_Entry
}

Scene :: struct {
	manifest: Entity_Manifest,
}