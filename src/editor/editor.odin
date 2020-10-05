package editor

import "shared:wb"
import "shared:wb/imgui"

import "../configs"
import "../entity"

enabled := false;

init :: proc() {
}

update :: proc(dt: f32) {
    if wb.get_input(configs.key_config.toggle_editor) {
        enabled = !enabled;
    }

    if !enabled do return;

    draw_entity_inspector();
}

render :: proc(render_graph: ^wb.Render_Graph) {
    
}

draw_entity_inspector :: proc() {
    if imgui.begin("Entity Inspector") {

    } imgui.end();

    if imgui.begin("Scene Hierarchy") {
        @static add_scene_buf: [64]u8;
        scene_to_add := do_input_text(add_scene_buf[:]);
        imgui.same_line();
        if imgui.button("Add Scene") {
            // TODO add scene
        }

        for scene_id, scene in entity.loaded_scenes {
            if imgui.tree_node_ex(scene_id, imgui.Tree_Node_Flags.CollapsingHeader) {

            }
        }

    } imgui.end();
}

do_input_text :: proc(buf: []byte) -> string {
    imgui.input_text("", buf);
    buf[len(buf)-1] = 0;
    text := cast(string)cast(cstring)&buf[0];
    return text;
}