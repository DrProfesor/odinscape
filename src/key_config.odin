package main

import "core:os"
import "core:mem"

import wb   "shared:workbench"
import wbml "shared:workbench/wbml"

Key_Config :: struct {
	camera_up:      wb.Input,
	camera_down:    wb.Input,
	camera_forward: wb.Input,
	camera_back:    wb.Input,
	camera_left:    wb.Input,
	camera_right:   wb.Input,

	camera_snap_to_unit: wb.Input,
	free_camera: wb.Input,
	camera_enable_mouse_rotation: wb.Input,

	select_unit: wb.Input,

	add_unit_to_selection_modifier: wb.Input,

	queue_command_modifier: wb.Input,
	move_command: wb.Input,
}

key_config: Key_Config;

key_config_item: ^wb.Catalog_Item;

PATH :: "resources/data/key_config.wbml";

init_key_config :: proc() {
	data, ok := os.read_entire_file(PATH);
	if !ok {
		key_config = default_key_config();
		key_config_save();
	}
	else {
		// apply our saved config on top of the default one, so defaults for new keys are preserved
		default_key_config := default_key_config();
		wbml.deserialize(cast(string)data, &default_key_config);
		key_config = default_key_config;
	}
}

key_config_save :: proc() {
	serialized := wbml.serialize(&key_config);
	defer delete(serialized);
	os.write_entire_file(PATH, cast([]u8)serialized);
}

default_key_config :: proc() -> Key_Config {
	using wb.Input;

	return Key_Config{
		camera_up      = Space,
		camera_down    = Left_Control,
		camera_forward = W,
		camera_back    = S,
		camera_left    = A,
		camera_right   = D,

		camera_snap_to_unit = Mouse_Middle,
		free_camera = Tab,
		camera_enable_mouse_rotation = Mouse_Right,

		select_unit = Mouse_Left,
		add_unit_to_selection_modifier = Left_Shift,

		queue_command_modifier = Left_Shift,
		move_command = Mouse_Right,
	};
}