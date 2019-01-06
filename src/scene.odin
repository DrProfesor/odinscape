package main

using import    "core:math"
using import    "core:fmt"
using import    "core:strings"
      import    "core:os"
      import    "shared:workbench/wbml"
      import wb "shared:workbench"
      import laas "shared:workbench/laas"

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
scene_init :: proc(scene_id : string) -> Scene {
	manifest_data, ok := os.read_entire_file(tprint(SCENE_DIRECTORY, scene_id, "/", scene_id, ".manifest"));
	assert(ok, tprint(SCENE_DIRECTORY, scene_id, "/", scene_id, ".manifest"));
	defer delete(manifest_data);

	scene := Scene{};
	scene.id = scene_id;

	scene.manifest = wbml.deserialize(Entity_Manifest, string(manifest_data));

	for entry, i in scene.manifest.entries {

		switch entry.asset_type {
			case Asset_Type.Model: {
				if current, ok := loaded_models[entry.id]; ok {
					current.count += 1;
					loaded_models[entry.id] = current;
				} else {

					// @Alloc this will be owned by the catalog and freed when unsubscribe is called
					userdata_entry : ^Manifest_Entry = new_clone(scene.manifest.entries[i]);

					catalog_subscriptions[entry.id] = wb.catalog_subscribe(tprint(RESOURCES, entry.path), userdata_entry,
						proc(entry: ^Manifest_Entry, entry_data: []u8) {
							defer delete(entry_data);
							existing, ok := loaded_models[entry.id];
							if ok {
								path := strings.new_cstring(tprint(RESOURCES, entry.path));
								defer delete(path);
								new_model := wb.buffer_model(wb.load_model_from_file(path));

								wb.release_model(existing.asset);
								existing.asset = new_model;

								loaded_models[entry.id] = existing;
							} else {
								// TODO (jake): don't do this, use load_model_from_memory, same with #43
								// too lazy to figure it out now though
								path := strings.new_cstring(tprint(RESOURCES, entry.path));
								defer delete(path);
								model := wb.buffer_model(wb.load_model_from_file(path));
								// end of bad

								/*
									// @Alloc 
									Model_Asset so mesh renderers do not have to poll the scene
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
				if current, ok := loaded_textures[entry.id]; ok {
					current.count += 1;
					loaded_textures[entry.id] = current;
				} else {
					// @Alloc this will be owned by the catalog and freed when unsubscribe is called
					userdata_entry : ^Manifest_Entry = new_clone(scene.manifest.entries[i]);

					catalog_subscriptions[entry.id] = wb.catalog_subscribe(tprint(RESOURCES, entry.path), userdata_entry,
						proc(entry: ^Manifest_Entry, entry_data: []u8) {
							defer delete(entry_data);
							if existing, ok := loaded_textures[entry.id]; ok {
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

	all_entity_files := wb.get_all_entries_strings_in_directory(tprint(SCENE_DIRECTORY, scene_id, "/entities"), true);

	using laas;

	for entity_file in all_entity_files {

		trim_len := len(tprint(SCENE_DIRECTORY, scene_id, "/entities"));
		entity_id := wb.parse_int(entity_file[trim_len+1:len(entity_file)-2]);
		entity_name := "nil";

		entity_data, ok := os.read_entire_file(entity_file);

		lexer := Lexer{string(entity_data), 0,0,0,nil};
		token: Token;

		depth := 0;
		block_start_idx := 0;
		component_type := "";

		components := make([dynamic]string, 0, 10);
		component_types := make([dynamic]string, 0, 10);

		get_next_token(&lexer, &token);
		if name_token, is_identifier := token.kind.(laas.String); is_identifier {
			entity_name = name_token.value;
		}

		for get_next_token(&lexer, &token) {
			switch value_kind in token.kind {
				case Symbol: {
					switch value_kind.value {
						case '{':{
							depth += 1;
							if depth == 1 do
								block_start_idx = lexer.lex_idx;
						}
						case '}':{
							depth -= 1;
							if depth == 0 {
								block := entity_data[block_start_idx-1:lexer.lex_idx];
								append(&components, string(block));
								append(&component_types, component_type);
							}
						}
					}
				}
				case Identifier: {
					if depth == 0 {
						component_type = token.slice_of_text;
					}
				}
			}
		}

		deserialize_entity_comnponents(entity_id, components, component_types, entity_name);
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
							wb.release_model(asset.asset);
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
							wb.release_texture(asset.asset);
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

	serialized_manifest: Builder;
	sbprint(&serialized_manifest, wbml.serialize(&scene.manifest));
	os.write_entire_file(tprint(SCENE_DIRECTORY, scene.id, "/", scene.id, ".manifest"), cast([]u8) to_string(serialized_manifest));

	for entity, _ in all_entities {
		serialized_entity := serialize_entity_components(entity);
		generated_code: Builder;
		sbprint(&generated_code, serialized_entity);
		os.write_entire_file(tprint(SCENE_DIRECTORY, scene.id, "/entities/", entity, ".e"), cast([]u8) to_string(generated_code));
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

get_texture :: proc(id: string, loc := #caller_location) -> wb.Texture {
	texture, ok := loaded_textures[id];
	assert(ok, tprint("Could not find texture asset with id:", id, loc));
	return texture.asset;
}


//
// Scene Data
//

Scene :: struct {
	id: string, 
	manifest: Entity_Manifest,
	entity_components: Entity_Components,
}

Entity_Manifest :: struct {
	entries: [dynamic]Manifest_Entry
	entity_list: [dynamic]Entity,
}

Manifest_Entry :: struct {
	id: string,
	path: string,
	asset_type: Asset_Type,
}

Entity_Components :: struct {
	_data: string,
}