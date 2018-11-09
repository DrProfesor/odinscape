package main

using import    "core:fmt"
using import    "core:math"
	  import wb "shared:workbench"
	  import ai "shared:odin-assimp"
	  import    "core:mem"

logln :: wb.logln;

main :: proc() {
    wb.make_simple_window("OdinScape", 1920, 1080, 3, 3, 120, wb.Scene{"Main", main_init, main_update, main_render, main_end});
}

meshId : wb.MeshID;

main_init :: proc() {
	wb.perspective_camera(85);
	init_entities();
	wb.camera_position = Vec3{0, 0, -10};

	/*
	scene := ai.import_file("D:\\Projects\\OdinProjects\\odinscape\\Resources\\Models\\cube.fbx",
		cast(u32) ai.aiPostProcessSteps.CalcTangentSpace |
		cast(u32) ai.aiPostProcessSteps.Triangulate |
		cast(u32) ai.aiPostProcessSteps.JoinIdenticalVertices |
		cast(u32) ai.aiPostProcessSteps.SortByPType |
		cast(u32) ai.aiPostProcessSteps.FlipWindingOrder);
	defer ai.release_import(scene);

	logln("Scene: ", scene^);
	meshes := mem.slice_ptr(scene^.mMeshes, cast(int) scene.mNumMeshes);
	for mesh in meshes
	{
		logln("Mesh: ", mesh^);
		verts := mem.slice_ptr(mesh.mVertices, cast(int) mesh.mNumVertices);
		norms := mem.slice_ptr(mesh.mNormals, cast(int) mesh.mNumVertices);

		processedVerts := make([dynamic]wb.Vertex3D, 0, mesh.mNumVertices);

		for i in 0 .. mesh.mNumVertices - 1
		{
			normal := norms[i];
			position := verts[i];

			r : f32 = (cast(f32)i / cast(f32)len(verts)) * 0.75 + 0.25;
			g : f32 = 0;
			b : f32 = 0;

			vert := wb.Vertex3D{
				Vec3{position.x, position.y, position.z},
				Vec2{0,0},
				wb.Colorf{r, g, b, 1},
				Vec3{normal.x, normal.y, normal.z}};

			append(&processedVerts, vert);
		}

		meshId = wb.create_mesh(processedVerts);
	}
	*/
}

main_update :: proc(dt: f32) {
    if wb.get_key_down(wb.Key.Escape) do wb.exit();

    if wb.get_key(wb.Key.Space) do wb.camera_position.y += 0.1;
	if wb.get_key(wb.Key.Left_Control) do wb.camera_position.y -= 0.1;
	if wb.get_key(wb.Key.W) do wb.camera_position.z += 0.1;
	if wb.get_key(wb.Key.S) do wb.camera_position.z -= 0.1;
	if wb.get_key(wb.Key.A) do wb.camera_position.x += 0.1;
	if wb.get_key(wb.Key.D) do wb.camera_position.x -= 0.1;

	update_entities();
}

main_render :: proc(dt: f32) {
	wb.use_program(wb.shader_rgba_3d);
	render_entities();
	// wb.draw_mesh(meshId, Vec3{0.0, 0.0, 0.0});
}

main_end :: proc() {
	shutdown_entities();
}