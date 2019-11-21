package editor

using import "core:fmt"
using import "core:strings"

using import    "shared:workbench/types"
using import    "shared:workbench/basic"
using import    "shared:workbench/logging"

import "shared:workbench/external/imgui"

RESOURCES_DIR :: "resources";

file_paths : [dynamic]string; 
current_drag_drop_payload : string;

init_resources_window :: proc() {
    file_paths = make([dynamic]string, 0, 50);
}

update_resources_window :: proc(dt:f32) {
    
    // TODO allow for loading and unloading based on what is used
    // may be a wb thing?
    if imgui.begin("Resources", nil) {
        
        recurse_into_path(RESOURCES_DIR);
        
    } imgui.end();
    
    recurse_into_path :: proc(path: string) {
        
        for path in get_all_paths(path) {
            flags : imgui.Tree_Node_Flags;
            
            if path.is_directory {
                flags = imgui.Tree_Node_Flags.CollapsingHeader;// | imgui.Tree_Node_Flags.NoTreePushOnOpen;
            } else {
                flags = imgui.Tree_Node_Flags.Leaf;
            }
            
            if imgui.tree_node_ext(path.file_name, flags) {
                
                if path.is_directory do 
                    recurse_into_path(path.path);
                
                if imgui.begin_drag_drop_source(imgui.Drag_Drop_Flags(0), 0) {
                    
                    if current_drag_drop_payload == "" do
                        current_drag_drop_payload = clone(path.path);
                    
                    imgui.set_drag_drop_payload("resource", &current_drag_drop_payload, uint(len(current_drag_drop_payload)), imgui.Set_Cond.Always);
                    imgui.text(path.path);
                    imgui.end_drag_drop_source();
                }
                
                imgui.tree_pop();
            }
        }
    }
}