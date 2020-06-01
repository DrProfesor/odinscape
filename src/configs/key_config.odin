package configs

import "core:os"
import "core:mem"
import "core:fmt"

import wb   "shared:wb"
import platform "shared:wb/platform"
import wbml "shared:wb/wbml"

Game_Input :: platform.Input;

Key_Config :: struct {

    // Editor
	toggle_editor: Game_Input,

	camera_up:      Game_Input,
	camera_down:    Game_Input,
	camera_forward: Game_Input,
	camera_back:    Game_Input,
	camera_left:    Game_Input,
	camera_right:   Game_Input,
    camera_speed_boost: Game_Input,

	camera_free_move: Game_Input,
	camera_scroll: Game_Input,
    editor_select: Game_Input,

    // Game
    interact : Game_Input,
    select : Game_Input,

    spell_1 : Game_Input,
    spell_2 : Game_Input,
    spell_3 : Game_Input,
    spell_4 : Game_Input,
    spell_5 : Game_Input,
}

key_config: Key_Config;

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
		wbml.deserialize(data, &default_key_config);
		key_config = default_key_config;
	}
}

key_config_save :: proc() {
	serialized := wbml.serialize(&key_config);
	defer delete(serialized);
	os.write_entire_file(PATH, transmute([]u8)serialized);
}

default_key_config :: proc() -> Key_Config {
	using platform.Input;

	return Key_Config{
		toggle_editor = F2,

		// Editor
		camera_up      = E,
		camera_down    = Q,
		camera_forward = W,
		camera_back    = S,
		camera_left    = A,
		camera_right   = D,
        camera_speed_boost = Shift,

		camera_scroll = Mouse_Middle,
		camera_free_move = Mouse_Right,
        editor_select = Mouse_Left,

		// Game
		interact = Mouse_Right,
		select = Mouse_Left,
	    spell_1 = Q,
	    spell_2 = W,
		spell_3 = E,
	    spell_4 = R,
	    spell_5 = T,
	};
}

input_to_nice_name :: proc(input: platform.Input) -> string {
	using platform.Input;

	#partial switch input {
		case Mouse_Left:          return "LMB";
		case Mouse_Right:          return "RMB";
		case Mouse_Middle:          return "MMB";
		case Space:                   return "Space";
		case Apostrophe:              return "Apostrophe";
		case Comma:                   return "Comma";
		case Minus:                   return "Minus";
		case Period:                  return "Period";
		case Forward_Slash:           return "Slash";
		case Semicolon:               return "Semicolon";
		case NR_0:                    return "0";
		case NR_1:                    return "1";
		case NR_2:                    return "2";
		case NR_3:                    return "3";
		case NR_4:                    return "4";
		case NR_5:                    return "5";
		case NR_6:                    return "6";
		case NR_7:                    return "7";
		case NR_8:                    return "8";
		case NR_9:                    return "9";
		case A:                       return "A";
		case B:                       return "B";
		case C:                       return "C";
		case D:                       return "D";
		case E:                       return "E";
		case F:                       return "F";
		case G:                       return "G";
		case H:                       return "H";
		case I:                       return "I";
		case J:                       return "J";
		case K:                       return "K";
		case L:                       return "L";
		case M:                       return "M";
		case N:                       return "N";
		case O:                       return "O";
		case P:                       return "P";
		case Q:                       return "Q";
		case R:                       return "R";
		case S:                       return "S";
		case T:                       return "T";
		case U:                       return "U";
		case V:                       return "V";
		case W:                       return "W";
		case X:                       return "X";
		case Y:                       return "Y";
		case Z:                       return "Z";
		case Escape:                  return "Escape";
		case Enter:                   return "Enter";
		case Tab:                     return "Tab";
		case Backspace:               return "Backspace";
		case Insert:                  return "Insert";
		case Delete:                  return "Delete";
		case Right:                   return "Right";
		case Left:                    return "Left";
		case Down:                    return "Down";
		case Up:                      return "Up";
		case Page_Up:                 return "Page Up";
		case Page_Down:               return "Page Down";
		case Home:                    return "Home";
		case End:                     return "End";
		case Caps_Lock:               return "Caps Lock";
		case Scroll_Lock:             return "Scroll Lock";
		case Num_Lock:                return "Num Lock";
		case Print_Screen:            return "Print Screen";
		case Pause:                   return "Pause";
		case F1:                      return "F1";
		case F2:                      return "F2";
		case F3:                      return "F3";
		case F4:                      return "F4";
		case F5:                      return "F5";
		case F6:                      return "F6";
		case F7:                      return "F7";
		case F8:                      return "F8";
		case F9:                      return "F9";
		case F10:                     return "F10";
		case F11:                     return "F11";
		case F12:                     return "F12";
	}

	assert(false, fmt.tprint(input));
	return "";
}