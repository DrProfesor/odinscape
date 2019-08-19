package main

import platform "shared:workbench/platform"

editor_enabled := false;

editor_init :: proc() {

}

editor_update :: proc() {

	if (platform.get_input_down(key_config.toggle_editor)) {
		editor_enabled = !editor_enabled;
	}

	if !editor_enabled do return;

	// Editor move camera
	if platform.get_input(key_config.camera_scroll) {

	} 
	else if platform.get_input(key_config.camera_free_move) {

	}

	draw_entity_window();
}