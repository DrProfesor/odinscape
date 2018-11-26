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

catalog_subscriptions: map[string]wb.Catalog_Item_ID;

// Initialize the scene with an ID, this corresponds to a file inside of /resources/scenes
// All entities in the manifest will be loaded and we will return a Scene object
// The scene object should be used to update and end the scene
scene_init :: proc(scene_file : string) -> Scene {
	scene_data, ok := os.read_entire_file(tprint(SCENE_DIRECTORY, scene_file, ".scene"));
	assert(ok, tprint("Couldn't find ", SCENE_DIRECTORY, scene_file, ".scene"));
	defer delete(scene_data);

	scene := wbml.deserialize(Scene, string(scene_data));

	for _, i in 0 .. len(scene.manifest.entries)-1 {

		entry := scene.manifest.entries[i];

		switch entry.asset_type {
			case Asset_Type.Model: {
				_, ok2 := loaded_models[entry.id];
				if ok2 {
					current := loaded_models[entry.id];
					current.count += 1;
					loaded_models[entry.id] = current;
				} else {

					// @Alloc this will be owned by the catalog and freed when unsubscribe is called
					userdata_entry := new_clone(scene.manifest.entries[i]);

					catalog_subscriptions[entry.id] = wb.catalog_subscribe(tprint(RESOURCES, entry.path), userdata_entry, 
						proc(entry: ^Manifest_Entry, entry_data: []u8) {
							defer delete(entry_data);
							existing, ok := loaded_models[entry.id];
							if ok {
								path := strings.new_cstring(tprint(RESOURCES, entry.path));
								new_model := wb.buffer_model(wb.load_model_from_file(path));
								
								wb.release_model(existing.asset);
								existing.asset = new_model;
							
								loaded_models[entry.id] = existing;
							} else {
								// TODO (jake): don't do this, use load_model_from_memory, same with #43 
								// too lazy to figure it out now though
								path := strings.new_cstring(tprint(RESOURCES, entry.path));
								model := wb.buffer_model(wb.load_model_from_file(path));
								// end of bad
								
								/* 
									@Alloc Model_Asset so mesh renderers do not have to poll the scene
								    This is owned by the scene and will be freed when the scene is ended
								    if not other scene is using the same asset
								*/
								loaded_models[entry.id] = new_clone(Model_Asset{model, 1});
							}
						});
				}
				break;
			}
			case Asset_Type.Texture: {
				_, ok2 := loaded_textures[entry.id];
				if ok2 {
					current := loaded_textures[entry.id];
					current.count += 1;
					loaded_textures[entry.id] = current;
				} else {
					// @Alloc this will be owned by the catalog and freed when unsubscribe is called
					userdata_entry := new_clone(scene.manifest.entries[i]);

					catalog_subscriptions[entry.id] = wb.catalog_subscribe(tprint(RESOURCES, entry.path), userdata_entry, 
						proc(entry: ^Manifest_Entry, entry_data: []u8) {
							defer delete(entry_data);
							existing, ok := loaded_textures[entry.id];
							if ok {
								wb.rebuffer_texture(existing.asset, entry_data);
							} else {
								texture := wb.load_texture(entry_data);
								loaded_textures[entry.id] = Texture_Asset{texture, 1};
							}
						});
				}
				break;
			}
		}
	}

	return scene;
}

scene_update :: proc(using scene: Scene) {

}

scene_end :: proc(using scene: Scene) {
	for entry in manifest.entries {
		switch entry.asset_type {
			case Asset_Type.Model: {
				asset, ok := loaded_models[entry.id];
				if ok {
					if asset.count <= 1 {
						subscription, ok2 := catalog_subscriptions[entry.id];
						if ok2 {
							wb.catalog_unsubscribe(subscription);
						}
						delete_key(&loaded_models, entry.id);
					} else {
						asset.count = asset.count - 1;
						loaded_models[entry.id] = asset;
					}
				}
				break;
			}
			case Asset_Type.Texture: {
				asset, ok := loaded_textures[entry.id];
				if ok {
					if asset.count <= 1 {
						subscription, ok2 := catalog_subscriptions[entry.id];
						if ok2 {
							wb.catalog_unsubscribe(subscription);
						}
						delete_key(&loaded_textures, entry.id);
					} else {
						asset.count = asset.count - 1;
						loaded_textures[entry.id] = asset;
					}
				}
				break;
			}
		}
	}
}

//
// Models
//
loaded_models : map[string]^Model_Asset;

Model_Asset :: struct {
	asset: wb.Model,
	count: int,
}

get_model :: proc(id: string) -> ^Model_Asset {
	model, ok := loaded_models[id];
	assert(ok, tprint("Could not find model asset with id:", id));
	return model;
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