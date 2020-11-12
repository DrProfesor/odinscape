package physics

import "core:fmt"
import "core:strings"
import "core:runtime"
import "core:math"
import la "core:math/linalg"

import "shared:wb/basic"
import "shared:wb/logging"
import "shared:wb"

import "../entity"
import "../util"
import "../shared"

init :: proc() {
}

update :: proc(dt: f32) {
    for collider in &shared.g_collision_scene.colliders {
        if collider.userdata == nil do continue;

        e := cast(^entity.Entity) collider.userdata;
        #partial switch kind in e.kind {
            case entity.Simple_Model: {
                collision_model := collider.info.kind.(wb.Collision_Model);
                collision_model.model_id = kind.model_id;
            }
        }

        wb.update_collider(collider, e.position, e.scale, collider.info, e);
    }
}

Raycast_Hit :: struct {
    hit_pos: Vector3,
    entity: ^entity.Entity,
}

wb_hits: [dynamic]wb.Hit_Info;

raycast :: proc(origin, direction: Vector3, hits: ^[dynamic]Raycast_Hit = nil) -> int {
    clear(hits);

    wb.linecast(&shared.g_collision_scene, origin, direction, &wb_hits);

    if hits != nil do for wb_hit in wb_hits {
        append(hits, Raycast_Hit{
            wb_hit.point0,
            cast(^entity.Entity) wb_hit.collider.userdata
        });
    }

    return len(wb_hits);
}

_internal_hits: [dynamic]Raycast_Hit;
point_walkable :: proc(point: Vector3, radius: f32, leg_buffer: f32 = 0.5) -> bool {
    hits := raycast(point + Vector3{0,radius,0}, Vector3{0,-1,0}, &_internal_hits);

    if hits == 0 do return false;

    for hit in _internal_hits {
        if abs(point.y - hit.hit_pos.y) > radius + leg_buffer do continue;
        if hit.entity == nil || !strings.contains(hit.entity.tags, "ground") do continue;
        return true;
    }

    return false;
}

entity_has_collision :: proc(e: ^entity.Entity) -> bool {
    #partial switch kind in e.kind {
        case entity.Simple_Model: {
            return kind.is_raycast_target;
        }
        case: return false;
    }
}


Quaternion :: wb.Quaternion;
Vector2 :: wb.Vector2;
Vector3 :: wb.Vector3;
Vector4 :: wb.Vector4;

pow                :: math.pow;
to_radians         :: math.to_radians_f32;
to_radians_f64     :: math.to_radians_f64;
to_degrees         :: math.to_degrees_f32;
to_degrees_f64     :: math.to_degrees_f64;
ortho3d            :: la.matrix_ortho3d;
perspective        :: la.matrix4_perspective;
transpose          :: la.transpose;
translate          :: la.matrix4_translate;
mat4_scale         :: la.matrix4_scale;
mat4_inverse       :: la.matrix4_inverse;
quat_to_mat4       :: la.matrix4_from_quaternion;
mul                :: la.mul;
length             :: la.length;
norm               :: la.normalize;
dot                :: la.dot;
cross              :: la.cross;
asin               :: math.asin;
acos               :: math.acos;
atan               :: math.atan;
atan2              :: math.atan2;
floor              :: math.floor;
ceil               :: math.ceil;
cos                :: math.cos;
sin                :: math.sin;
sqrt               :: math.sqrt;
slerp              :: la.quaternion_slerp;
quat_norm          :: la.quaternion_normalize;
angle_axis         :: la.quaternion_angle_axis;
identity           :: la.identity;
quat_inverse       :: la.quaternion_inverse;
lerp               :: math.lerp;
quat_mul_vec3      :: la.quaternion_mul_vector3;
mod                :: math.mod;

log_info :: util.log_info;
log_debug :: util.log_debug;
log_warn :: util.log_warn;
log_error :: util.log_error;
