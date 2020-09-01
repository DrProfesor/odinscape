package save

import "core:os"
import "core:fmt"

import "shared:wb/wbml"

PLAYER_SAVES_DIRECTORY := "saves/";

loaded_player_data : map[string]Player_Save;

init_save :: proc() {

}

load_player_save :: proc(username: string) -> Player_Save {
	bytes, ok := os.read_entire_file(fmt.tprint(PLAYER_SAVES_DIRECTORY, username, ".wbml"));
	save : Player_Save;

	if ok {
		wbml.deserialize(bytes, &save);
	} else {
		save = Player_Save { username, {} };

		bytes := wbml.serialize(&save);
	    defer delete(bytes);
	    os.write_entire_file(fmt.tprint(PLAYER_SAVES_DIRECTORY, username, ".wbml"), transmute([]u8)bytes);

		// TODO any defaults
	}

	loaded_player_data[username] = save;

	return loaded_player_data[username];
}

unload_player_save :: proc(username: string) {
	save, exists := loaded_player_data[username];
	assert(exists, "Could not find player in save.");

	bytes := wbml.serialize(&save);
    defer delete(bytes);
    os.write_entire_file(fmt.tprint(PLAYER_SAVES_DIRECTORY, username, ".wbml"), transmute([]u8)bytes);

    delete_key(&loaded_player_data, username);
}

// Master player account data
Player_Save :: struct {
	username: string,
	// TODO password
	
	characters: [10]Character_Save,
}

Character_Save :: struct {
	character_name: string,

	// TODO
	// customization data
	// level
	// health / mana
	// equipment
	// quests
	// spells
	// talents
	// guild
	// inventory
	// anything else about the player
}