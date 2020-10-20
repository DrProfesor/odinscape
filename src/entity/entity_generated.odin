package entity

import "shared:wb"

all_Player_Character: [dynamic]^Player_Character;
all_Enemy: [dynamic]^Enemy;
all_Simple_Model: [dynamic]^Simple_Model;
all_Directional_Light: [dynamic]^Directional_Light;

Entity_Union :: union {
	Player_Character,
	Enemy,
	Simple_Model,
	Directional_Light,
}

entity_typeids := [4]typeid{
	typeid_of(Player_Character),
	typeid_of(Enemy),
	typeid_of(Simple_Model),
	typeid_of(Directional_Light),
};

_add_entity :: proc(e: ^Entity) {
	switch kind in e.kind {
		case Player_Character: { 
			append(&all_Player_Character, cast(^Player_Character) e); 
			(cast(^Player_Character) e).base = e;
		}
		case Enemy: { 
			append(&all_Enemy, cast(^Enemy) e); 
			(cast(^Enemy) e).base = e;
		}
		case Simple_Model: { 
			append(&all_Simple_Model, cast(^Simple_Model) e); 
			(cast(^Simple_Model) e).base = e;
		}
		case Directional_Light: { 
			append(&all_Directional_Light, cast(^Directional_Light) e); 
			(cast(^Directional_Light) e).base = e;
		}
	}
}

_destroy_entity :: proc(e: ^Entity) {
	switch kind in e.kind {
		case Player_Character: for ep, i in all_Player_Character do if cast(^Entity) ep == e { unordered_remove(&all_Player_Character, i); break; }
		case Enemy: for ep, i in all_Enemy do if cast(^Entity) ep == e { unordered_remove(&all_Enemy, i); break; }
		case Simple_Model: for ep, i in all_Simple_Model do if cast(^Entity) ep == e { unordered_remove(&all_Simple_Model, i); break; }
		case Directional_Light: for ep, i in all_Directional_Light do if cast(^Entity) ep == e { unordered_remove(&all_Directional_Light, i); break; }
	}
}

create_entity_by_type :: proc(t: typeid) -> Entity {
    e := _create_entity();

    switch t {
		case Player_Character: e.kind = Player_Character{};
		case Enemy: e.kind = Enemy{};
		case Simple_Model: e.kind = Simple_Model{};
		case Directional_Light: e.kind = Directional_Light{};
    }

    return e;
}

init_entity :: proc(e: ^Entity, is_creation := false) {
    #partial switch kind in e.kind {
		case Simple_Model: init_simple_model(cast(^Simple_Model) e, is_creation);
		case Directional_Light: init_directional_light(cast(^Directional_Light) e, is_creation);
        case: break;
    }
}

