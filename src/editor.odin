package main

import platform "shared:workbench/platform"

editor_enabled := false;

editor_init :: proc() {

}

editor_update :: proc() {

	if (platform.get_input_down(key_config.toggle_editor)) {
		editor_enabled = !editor_enabled;
	}

	if (editor_enabled) {
		draw_entity_window();
	}
}