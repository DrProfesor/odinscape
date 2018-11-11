package main

using import       "core:fmt"
using import       "core:math"
	  import imgui "shared:odin-imgui"
	  import wb    "shared:workbench"
	  import       "core:mem"

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
}

//
// Sprite_Renderer
//

Sprite_Renderer :: struct {
	entity: Entity,
	color: wb.Colorf,
}

render_sprite_renderer :: inline proc(using sprite: ^Sprite_Renderer) {
	tf := get_component(entity, Transform);
	wb.im_quad(wb.rendermode_world, wb.shader_rgba, tf.position-Vec3{1, 1, 0}, tf.position+Vec3{1, 1, 0}, color);
}

//
// Spinner component
//

Spinner_Component :: struct {
	entity: Entity,
	speed: f32,
	radius: f32,
}

init_spinner :: inline proc(using spinner: ^Spinner_Component) {
	speed = wb.random_range(0.35, 1);
	radius = wb.random01() * 5;
	sprite := get_component(entity, Sprite_Renderer);
	sprite.color = wb.Colorf{wb.random01(), wb.random01(), wb.random01(), 1};
}

update_spinner :: inline proc(using spinner: ^Spinner_Component) {
	tf := get_component(entity, Transform);
	tf.position = Vec3{sin(wb.time * speed) * radius, cos(wb.time * speed) * radius, 0};
}

//
// Mesh Renderer
//
Mesh_Renderer :: struct {
	entity : Entity,
	mesh_ids : [dynamic]wb.MeshID,
}

render_mesh_renderer :: inline proc(using mesh_comp: ^Mesh_Renderer) {
	tf := get_component(entity, Transform);

	for mesh_id in mesh_ids {
		wb.draw_mesh(mesh_id, tf.position);
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