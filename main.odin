package main

import wb "shared:workbench"

main_init :: proc() {
	wb.perspective_camera(85);
}

main_update :: proc(dt: f32) {
    if wb.get_key_down(wb.Key.Escape) do wb.exit();
}

Render_Layer :: enum {
}

main_render :: proc(dt: f32) {
}

main_end :: proc() {
}

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Scene{"Main", main_init, main_update, main_render, main_end});
}