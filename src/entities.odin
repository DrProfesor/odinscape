package main

using import    "core:fmt"
using import    "core:math"
	  import wb "shared:workbench"
	  import    "core:mem"

Entity :: int;

last_entity_id: Entity;
all_entities: map[Entity]_Entity_Data;

new_entity :: proc() -> Entity {
	last_entity_id += 1;
	return last_entity_id;
}

get_all_components :: proc(entity: Entity) -> []Component_Type {
	e := all_entities[entity];
	return e.components[:];
}

//
// Transform
//

Transform :: struct {
	entity: Entity,
	position: Vec3,
}

all_transforms: [dynamic]Transform;

//
// Sprite_Renderer
//

Sprite_Renderer :: struct {
	entity: Entity,
	color: wb.Colorf,
}

all_sprite_renderers: [dynamic]Sprite_Renderer;

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

all_spinners: [dynamic]Spinner_Component;

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

all_mesh_renderers: [dynamic]Mesh_Renderer;

render_mesh_renderer :: inline proc(using meshComp: ^Mesh_Renderer) {

	tf := get_component(entity, Transform);

	for meshId in mesh_ids {
		wb.draw_mesh(meshId, tf.position);
	}
}

//
// Entities Internal
//

_Entity_Data :: struct {
	components: [dynamic]Component_Type
}

init_entities :: proc() {
	// // do test things
	// {
	// 	NUM_THINGS :: 50;
	// 	for i in 0..NUM_THINGS {
	// 		thing := new_entity();
	// 		add_component(thing, Transform);
	// 		add_component(thing, Sprite_Renderer);
	// 		add_component(thing, Spinner_Component);
	// 	}
	// }
}

update_entities :: proc() {
	call_component_updates();
}

render_entities :: proc() {
	call_component_renders();
}

shutdown_entities :: proc() {
}