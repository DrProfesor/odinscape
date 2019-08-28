package gizmo

using import "core:math"
using import "core:fmt"

import wb_plat "shared:workbench/platform"
import wb_gpu  "shared:workbench/gpu"
import wb_math  "shared:workbench/math"
import wb      "shared:workbench"
import         "shared:workbench/external/imgui"

manipulate :: proc(view, projection : Mat4, o: Operation, m: Mode, model: Mat4) -> Mat4 {
}


Operation :: enum {
    Translate,
    Rotate,
    Scale,
    Bounds,
}

Mode :: enum {
    Local, World
}