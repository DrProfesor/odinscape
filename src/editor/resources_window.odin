package editor

import "core:fmt"
import "core:strings"

import wb "shared:workbench"
import    "shared:workbench/types"
import    "shared:workbench/basic"
import    "shared:workbench/logging"
import    "shared:workbench/ecs"

import "shared:workbench/external/imgui"

import "../game"

RESOURCES_DIR :: "resources";

payload_data: Drag_Drop_Payload;
current_drag_drop_payload: string;

init_resources_window :: proc() {
}

update_resources_window :: proc(userdata: rawptr) {

    // TODO allow for loading and unloading based on what is used
    // may be a wb thing?
    if imgui.begin("Resources", nil) {
        recurse_into_path(RESOURCES_DIR);
    } imgui.end();

    recurse_into_path :: proc(path: string) {

        for path in basic.get_all_paths(path) {
            flags : imgui.Tree_Node_Flags;

            dir_target := "";
            if path.is_directory {
                flags = imgui.Tree_Node_Flags.CollapsingHeader;// | imgui.Tree_Node_Flags.NoTreePushOnOpen;
                dir_target = path.path;
            } else {
                flags = imgui.Tree_Node_Flags.Leaf;
                dir_target = path.parent_dir;
            }

            open := imgui.tree_node_ext(path.file_name, flags);

            if imgui.begin_popup_context_item("resource_context")
            {
                // TODO(jake) this crashes when the game starts again :S
                // @static entering_name := false;
                // @static folder_name_buffer: [64]u8;

                // if !entering_name {
                //     if imgui.button("Create Folder") {
                //         entering_name = true;
                //         folder_name_buffer = {};
                //     }
                // } else {

                //     if imgui.input_text("Name", folder_name_buffer[:], .EnterReturnsTrue) {
                //         folder_name_buffer[len(folder_name_buffer)-1] = 0;

                //         wb.create_directory(tprint(dir_target, "/", aprint(cast(string)cast(cstring)&folder_name_buffer[0])));

                //         entering_name = false;
                //         folder_name_buffer = {};
                //     }
                // }

                // File delete
                if !path.is_directory {
                    if imgui.button("Delete File") {
                        wb.delete_file(path.path);
                    }
                }

                imgui.end_popup();
            }

            if open {
                if path.is_directory do
                    recurse_into_path(path.path);

                if imgui.begin_drag_drop_source(imgui.Drag_Drop_Flags(0), 0) {

                    switch path.extension {
                        case "e": {
                            payload_data = Prefab_Payload {
                                path.path,
                            };
                        }
                    }

                    current_drag_drop_payload = path.path;

                    imgui.set_drag_drop_payload("resource", &payload_data, 1, imgui.Set_Cond.Always);
                    imgui.text(path.path);
                    imgui.end_drag_drop_source();
                }

                if imgui.begin_drag_drop_target() {
                    payload := imgui.accept_drag_drop_payload("entity", imgui.Drag_Drop_Flags(0));
                    //defer delete(payload);
                    if payload != nil {
                        entity_payload := transmute(^Entity_Payload) payload.data;
                        e, ok := ecs.scene.entity_datas[entity_payload.eid];
                        assert(ok);

                        ecs.create_prefab(entity_payload.eid, fmt.tprint(dir_target, "/", e.name, ".e"));
                        imgui.end_drag_drop_target();
                    }
                }

                imgui.tree_pop();
            }
        }
    }
}

Prefab_Payload :: struct {
    path: string,
}

Entity_Payload :: struct {
    eid: ecs.Entity,
}

Drag_Drop_Payload :: union {
    Entity_Payload,
    Prefab_Payload,
}