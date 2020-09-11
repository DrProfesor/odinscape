package save

import "core:os"
import "core:fmt"

import log "shared:wb/logging"
import "shared:wb/wbml"

import "../util"

PLAYER_SAVES_DIRECTORY :: "saves/";

loaded_player_data : map[string]Player_Save;

init_save :: proc() {

}

load_player_save :: proc(username: string) -> Player_Save {
	//file_name := "D:/Projects/OdinProjects/odinscape/release-server/saves/Doc.wbml";
	file_name := util.tprint(PLAYER_SAVES_DIRECTORY, username, ".wbml");
	bytes, ok := os.read_entire_file(file_name);
	save : Player_Save;

	if ok {
		wbml.deserialize(bytes, &save, context.allocator, context.allocator);
	} else {
		save = Player_Save { username, {} };

		bytes := wbml.serialize(&save);
	    defer delete(bytes);

	    log.logln("Writing save file to:", file_name);
	    log.logln(os.write_entire_file(file_name, transmute([]u8)bytes));
	}

	loaded_player_data[username] = save;

	return loaded_player_data[username];
}

unload_player_save :: proc(username: string) {
	save, exists := loaded_player_data[username];
	assert(exists, "Could not find player in save.");

	bytes := wbml.serialize(&save);
    defer delete(bytes);
    os.write_entire_file(util.tprint(PLAYER_SAVES_DIRECTORY, username, ".wbml"), transmute([]u8)bytes);

    delete_key(&loaded_player_data, username);
}

// Master player account data
Player_Save :: struct {
	username: string,
	// TODO hashed password
	
	characters: [10]Character_Save,
}

Character_Save :: struct {
	valid: bool,
	character_name: string,

	// customization data
	model_id: string, // TODO actual character customization
	texture_id: string,

	// stats
	stats: [16]Stat,

	// health / mana
	current_health: f32,
	current_mana: f32,
	// TODO maybe some players get energy/rage

	// spells
	unlocked_spells: [dynamic]Spell_Save,
	assigneable_slots: int,

	// equipment
	

	// quests
	

	// talents
	

	// guild
	

	// inventory
	

	// anything else about the player
}

Spell_Save :: struct {
	id: string,
	last_cast: f64,
	is_assigned: bool,
}

Stat :: struct {
    id: string,
    experience : f32,
    level : int,
}