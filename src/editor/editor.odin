package editor

import "shared:wb"
import "../configs"

Base_Speed : f32 = 5;

init :: proc() {
}

enabled_last_frame := false;

update :: proc(dt: f32) {
    // if !core.debug_window_open {
    //     enabled_last_frame = false;
    //     return;
    // }

    // if !enabled_last_frame {
    //     // set the camera back to the editor position
    //     // setting to play position will be handled by the camera controller
    //     core.main_camera.position = configs.editor_config.camera_position;
    //     core.main_camera.rotation = configs.editor_config.camera_rotation;
    // }

    // if wb_plat.get_input(configs.key_config.camera_free_move) {
    //     wb.do_camera_movement(wb.main_camera, dt, Base_Speed, Base_Speed * 3, Base_Speed * 0.3);

    //     configs.editor_config.camera_position = wb.main_camera.position;
    //     configs.editor_config.camera_rotation = wb.main_camera.rotation;
    // }

    enabled_last_frame = true;
}

render :: proc(render_graph: ^wb.Render_Graph) {
// TODO render terrain editor
// TODO render animation window
}