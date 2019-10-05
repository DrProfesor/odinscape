package main

using import "core:math"
import wb "shared:workbench"
using import "shared:workbench/logging"
using import "shared:workbench/types"
import "shared:workbench/gpu"


MAX_LIGHTS :: 100;
light_positions: [dynamic]Vec3;
light_colors:    [dynamic]Colorf;

push_light :: proc(position: Vec3, color: Colorf) {
	if len(light_positions) >= MAX_LIGHTS {
		logln("Too many lights! The max is ", MAX_LIGHTS);
		return;
	}
	append(&light_positions, position);
	append(&light_colors,    color);
}

flush_lights_to_shader :: proc(program: gpu.Shader_Program) {
	num_lights := i32(len(light_positions));
	if num_lights > 0 {
		gpu.uniform3fv(program, "light_positions", num_lights, &light_positions[0][0]);
		gpu.uniform4fv(program, "light_colors",    num_lights, &light_colors[0].r);
		gpu.uniform1i(program, "num_lights", cast(i32)len(light_positions));
	}
}

set_current_material :: proc(program: gpu.Shader_Program, material: wb.Material) {
	gpu.uniform_vec4 (program, "material.ambient",  transmute(Vec4)material.ambient);
	gpu.uniform_vec4 (program, "material.diffuse",  transmute(Vec4)material.diffuse);
	gpu.uniform_vec4 (program, "material.specular", transmute(Vec4)material.specular);
	gpu.uniform_float(program, "material.shine",    material.shine);
}

clear_lights :: proc() {
	clear(&light_positions);
	clear(&light_colors);
}