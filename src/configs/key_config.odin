package configs

import "core:os"
import "core:mem"
import "core:fmt"

import wb   "shared:workbench"
import platform "shared:workbench/platform"
import wbml "shared:workbench/wbml"

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
    move_to : Game_Input,
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
        camera_speed_boost = Left_Shift,

		camera_scroll = Mouse_Middle,
		camera_free_move = Mouse_Right,
        editor_select = Mouse_Left,

		// Game
		move_to = Mouse_Right,
	};
}

input_to_nice_name :: proc(input: platform.Input) -> string {
	using platform.Input;

	switch input {
		case Unknown:                 return "UNKNOWN";
		case Mouse_Button_1:          return "LMB";
		case Mouse_Button_2:          return "RMB";
		case Mouse_Button_3:          return "MMB";
		case Mouse_Button_4:          return "Mouse Button 4";
		case Mouse_Button_5:          return "Mouse Button 5";
		case Mouse_Button_6:          return "Mouse Button 6";
		case Mouse_Button_7:          return "Mouse Button 7";
		case Mouse_Button_8:          return "Mouse Button 8";
		case Space:                   return "Space";
		case Apostrophe:              return "Apostrophe";
		case Comma:                   return "Comma";
		case Minus:                   return "Minus";
		case Period:                  return "Period";
		case Slash:                   return "Slash";
		case Semicolon:               return "Semicolon";
		case Equal:                   return "Equal";
		case Left_Bracket:            return "Left Bracket";
		case Backslash:               return "Backslash";
		case Right_Bracket:           return "Right Bracket";
		case Grave_Accent:            return "Grave Accent";
		case World_1:                 return "World 1";
		case World_2:                 return "World 2";
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
		case F13:                     return "F13";
		case F14:                     return "F14";
		case F15:                     return "F15";
		case F16:                     return "F16";
		case F17:                     return "F17";
		case F18:                     return "F18";
		case F19:                     return "F19";
		case F20:                     return "F20";
		case F21:                     return "F21";
		case F22:                     return "F22";
		case F23:                     return "F23";
		case F24:                     return "F24";
		case F25:                     return "F25";
		case KP_0:                    return "Keypad 0";
		case KP_1:                    return "Keypad 1";
		case KP_2:                    return "Keypad 2";
		case KP_3:                    return "Keypad 3";
		case KP_4:                    return "Keypad 4";
		case KP_5:                    return "Keypad 5";
		case KP_6:                    return "Keypad 6";
		case KP_7:                    return "Keypad 7";
		case KP_8:                    return "Keypad 8";
		case KP_9:                    return "Keypad 9";
		case KP_Decimal:              return "Keypad Decimal";
		case KP_Divide:               return "Keypad Divide";
		case KP_Multiply:             return "Keypad Multiply";
		case KP_Subtract:             return "Keypad Subtract";
		case KP_Add:                  return "Keypad Add";
		case KP_Enter:                return "Keypad Enter";
		case KP_Equal:                return "Keypad Equal";
		case Left_Shift:              return "Left Shift";
		case Left_Control:            return "Left Control";
		case Left_Alt:                return "Left Alt";
		case Left_Super:              return "Left Super";
		case Right_Shift:             return "Right Shift";
		case Right_Control:           return "Right Control";
		case Right_Alt:               return "Right Alt";
		case Right_Super:             return "Right Super";
		case Key_Menu:                return "Key Menu";
	}

	assert(false, fmt.tprint(input));
	return "";
}