package main

using import       "core:fmt"
using import       "core:math"
	  import       "core:mem"

	  import wb    "shared:workbench"
	  import imgui "shared:workbench/external/imgui"
	  import coll  "shared:workbench/collision"

Entity :: distinct int;

last_entity_id: Entity;
all_entities: map[Entity]_Entity_Data;
entities_to_destroy: [dynamic]Entity;
available_component_lists: [dynamic][dynamic]Component_Type;

new_entity :: proc() -> Entity {
	last_entity_id += 1;
	e: _Entity_Data;
	if len(available_component_lists) > 0 {
		e.component_types = pop(&available_component_lists);
		assert(len(e.component_types) == 0, "list wasn't cleared before returning to available_component_lists");
	}
	all_entities[last_entity_id] = e;
	return last_entity_id;
}

get_all_component_types :: proc(entity: Entity) -> []Component_Type {
	e := all_entities[entity];
	return e.component_types[:];
}

destroy_entity :: proc(entity_id: Entity) {
	append(&entities_to_destroy, entity_id);
}

//
// Transform
//

Transform :: struct {
	entity: Entity,

	position: Vec3,
	scale: Vec3,
	rotation: Vec3,
}

identity_transform :: inline proc() -> Transform {
	return Transform{{}, {}, Vec3{1, 1, 1}, {}};
}

//
// Sprite_Renderer
//

Sprite_Renderer :: struct {
	entity: Entity,

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
	entity: Entity,

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
// Mesh Renderer
//
Mesh_Renderer :: struct {
	entity : Entity,

	mesh_ids : [dynamic]wb.MeshID,
}

render__Mesh_Renderer :: inline proc(using mesh_comp: ^Mesh_Renderer) {
	tf := get_component(entity, Transform);
	assert(tf != nil);
	for mesh_id in mesh_ids {
		wb.draw_mesh(mesh_id, tf.position, tf.scale, tf.rotation);
	}
}

destroy__Mesh_Renderer :: proc(using mesh_comp: ^Mesh_Renderer) {
	// todo: the Mesh_Renderer probably shouldn't own the `mesh_ids` memory
	delete(mesh_ids);
}

//
// Box Collider
//

Box_Collider :: struct {
	entity: Entity,

	offset_from_transform: Vec3,
	size: Vec3,
	handle: coll.Handle,
}

box_collider_identity :: proc() -> Box_Collider {
	return Box_Collider{
		{},
		{},
		Vec3{1, 1, 1},
		{},
	};
}

init__Box_Collider :: inline proc(using box: ^Box_Collider) {
	tf := get_component(entity, Transform);
	assert(tf != nil);
	handle = coll.add_collider_to_scene(&main_collision_scene, coll.Collider{tf.position + offset_from_transform, coll.Box{size * tf.scale}});
}

update__Box_Collider :: inline proc(using box: ^Box_Collider) {
	tf := get_component(entity, Transform);
	assert(tf != nil);

	collider, ok := coll.get_collider(&main_collision_scene, handle);
	assert(ok);

	collider.position = tf.position + offset_from_transform;

	b := &collider.kind.(coll.Box);
	b.size = size * tf.scale;

	coll.update_collider(&main_collision_scene, handle, collider);
}

destroy__Box_Collider :: inline proc(using box: ^Box_Collider) {
	coll.remove_collider(&main_collision_scene, handle);
}

//
// Units
//

Unit_Component :: struct {
	entity: Entity,

	move_speed: f32,

	using runtime_values: struct {
		has_target: bool,
		current_target: Vec3,
	}
}

update__Unit_Component :: inline proc(using unit: ^Unit_Component) {
	if has_target {
		tf := get_component(entity, Transform);
		if wb.sqr_magnitude(tf.position - current_target) < 0.01 {
			has_target = false;
		}
		else {
			tf.position += norm(current_target - tf.position) * move_speed * wb.fixed_delta_time;
		}
	}
}

//
// Entities Internal
//

_Entity_Data :: struct {
	component_types: [dynamic]Component_Type,
}

init_entities :: proc() {
}

update_entities :: proc() {
	destroy_marked_entities();
	call_component_updates();
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