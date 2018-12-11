package main

using import "core:fmt"
using import "core:math"
	  import "core:mem"

	  import wb    "shared:workbench"
	  import imgui "shared:workbench/external/imgui"
	  import coll  "shared:workbench/collision"

Entity :: distinct int;

last_entity_id           : Entity;
all_entities             : map[Entity]_Entity_Data;
entities_to_destroy      : [dynamic]Entity;
available_component_lists: [dynamic][dynamic]Component_Type;

new_entity :: proc(name: string = "") -> Entity {
	last_entity_id += 1;
	e: _Entity_Data;
	e.name = name;
	if len(available_component_lists) > 0 {
		e.component_types = pop(&available_component_lists);
		assert(len(e.component_types) == 0, "list wasn't cleared before returning to available_component_lists");
	}
	all_entities[last_entity_id] = e;
	return last_entity_id;
}
destroy_entity :: proc(entity_id: Entity) {
	append(&entities_to_destroy, entity_id);
}

destroyed :: proc(entity_id: Entity) -> bool {
	_, ok := all_entities[entity_id];
	if !ok do return true;
	for e in entities_to_destroy {
		if e == entity_id do return true;
	}
	return false;
}

get_all_component_types :: proc(entity: Entity) -> []Component_Type {
	e := all_entities[entity];
	return e.component_types[:];
}



Component_Base :: struct {
	entity: Entity,
}

//
// Transform
//

Transform :: struct {
	using base: Component_Base,

	position: Vec3,
	scale: Vec3,
	rotation: Vec3,

	velocity: Vec3,
}

transform :: inline proc(position := Vec3{0, 0, 0}, scale := Vec3{1, 1, 1}, rotation := Vec3{}) -> Transform {
	tf: Transform;
	tf.position = position;
	tf.scale = scale;
	tf.rotation = rotation;
	return tf;
}

debug_draw_entity_handles: bool;
render__Transform :: inline proc(using tf: ^Transform) {
	if debug_draw_entity_handles {
		wb.push_debug_line(wb.rendermode_world, position, position + Vec3{1, 0, 0}, wb.COLOR_RED);
		wb.push_debug_line(wb.rendermode_world, position, position + Vec3{0, 1, 0}, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, position, position + Vec3{0, 0, 1}, wb.COLOR_BLUE);
	}
}

//
// Sprite_Renderer
//

Sprite_Renderer :: struct {
	using base: Component_Base,

	color: wb.Colorf,
}

render__Sprite_Renderer :: inline proc(using sprite: ^Sprite_Renderer) {
	tf := get_component(entity, Transform);
	wb.im_quad(wb.rendermode_world, wb.shader_rgba, tf.position-Vec3{1, 1, 0}, tf.position+Vec3{1, 1, 0}, color);
}

//
// Spinner component
//

Spinner_Component :: struct {
	using base: Component_Base,

	orbit_distance: f32,
	orbit_speed: f32,
	torque: Vec3,
}

update__Spinner_Component :: inline proc(using spinner: ^Spinner_Component) {
	tf := get_component(entity, Transform);
	tf.position = Vec3{sin(wb.time * orbit_speed) * orbit_distance, cos(wb.time * orbit_speed) * orbit_distance, 0};
	tf.rotation += torque;
	tf.scale = Vec3{1, 1, 1} * (wb.sin01(wb.time)/2+0.5);

	q := wb.degrees_to_quaternion(tf.rotation);
	wb.push_debug_line(wb.rendermode_world, tf.position, tf.position + wb.quaternion_forward(q) * 10, wb.COLOR_GREEN);
	wb.push_debug_line(wb.rendermode_world, tf.position, tf.position + wb.quaternion_right(q) * 10, wb.COLOR_BLUE);
}

//
// Terrain
//

Terrain_Component :: struct {
	using base: Component_Base,
}

//
// Mesh Renderer
//
Mesh_Renderer :: struct {
	using base: Component_Base,

	model                 : ^Model_Asset,
	offset_from_transform : Vec3,
	color                 : wb.Colorf,
	texture_handle        : wb.Texture,
	shader_handle         : wb.Shader_Program,
}

render__Mesh_Renderer :: inline proc(using mesh_comp: ^Mesh_Renderer) {
	tf := get_component(entity, Transform);
	assert(tf != nil);

	for mesh_id in model.asset.meshes {
		wb.push_mesh(
			mesh_id,
			tf.position + offset_from_transform,
			tf.scale,
			tf.rotation,
			texture_handle,
			shader_handle,
			color,
		);
	}
}

//
// Box Collider
//

Box_Collider :: struct {
	using base: Component_Base,

	offset_from_transform: Vec3,
	size: Vec3,
}

box_collider :: proc(size := Vec3{1, 1, 1}, offset := Vec3{0, 0, 0}) -> Box_Collider {
	b: Box_Collider;
	b.size = size;
	b.offset_from_transform = offset;
	return b;
}

init__Box_Collider :: inline proc(using box: ^Box_Collider) {
	tf := get_component(entity, Transform);
	assert(tf != nil);
	coll.add_collider_to_scene(&main_collision_scene, coll.Collider{tf.position + offset_from_transform, coll.Box{size * tf.scale}}, entity);

	collider, ok := coll.get_collider(&main_collision_scene, entity);
	assert(ok);
}

debugging_colliders: bool;
update__Box_Collider :: inline proc(using box: ^Box_Collider) {
	tf := get_component(entity, Transform);
	assert(tf != nil);

	collider, ok := coll.get_collider(&main_collision_scene, entity);
	assert(ok);

	collider.position = tf.position + offset_from_transform;

	collider.box.size = size * tf.scale;

	coll.update_collider(&main_collision_scene, entity, collider);

	if debugging_colliders {
		origin := tf.position + offset_from_transform;
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{-size.x, -size.y, -size.z} * tf.scale * 0.5,
												origin + Vec3{-size.x,  size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);

		wb.push_debug_line(wb.rendermode_world, origin + Vec3{-size.x, -size.y, -size.z} * tf.scale * 0.5,
												origin + Vec3{ size.x, -size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{ size.x, -size.y, -size.z} * tf.scale * 0.5,
												origin + Vec3{ size.x,  size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{ size.x,  size.y, -size.z} * tf.scale * 0.5,
												origin + Vec3{-size.x,  size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);

		wb.push_debug_line(wb.rendermode_world, origin + Vec3{ size.x, -size.y, -size.z} * tf.scale * 0.5,
												origin + Vec3{ size.x, -size.y,  size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{ size.x, -size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{ size.x,  size.y,  size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{ size.x,  size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{ size.x,  size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);

		wb.push_debug_line(wb.rendermode_world, origin + Vec3{ size.x, -size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{-size.x, -size.y,  size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{-size.x, -size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{-size.x,  size.y,  size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{-size.x,  size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{ size.x,  size.y,  size.z} * tf.scale * 0.5, wb.COLOR_GREEN);

		wb.push_debug_line(wb.rendermode_world, origin + Vec3{-size.x, -size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{-size.x, -size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
		wb.push_debug_line(wb.rendermode_world, origin + Vec3{-size.x,  size.y,  size.z} * tf.scale * 0.5,
												origin + Vec3{-size.x,  size.y, -size.z} * tf.scale * 0.5, wb.COLOR_GREEN);
	}
}

destroy__Box_Collider :: inline proc(using box: ^Box_Collider) {
	coll.remove_collider(&main_collision_scene, entity);
}

//
// Entities Internal
//

_Entity_Data :: struct {
	name: string,
	component_types: [dynamic]Component_Type,
}

init_entities :: proc() {
}

update_entities :: proc() {
	call_component_updates();
	destroy_marked_entities();
}

render_entities :: proc() {
	call_component_renders();
}

shutdown_entities :: proc() {
	for id, data in all_entities {
		destroy_entity(id);
	}
	destroy_marked_entities();
	assert(len(all_entities) == 0);
}