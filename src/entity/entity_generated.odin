package entity

import "shared:wb"

all_Player_Character: [dynamic]^Player_Character;
all_Enemy: [dynamic]^Enemy;
all_Simple_Model: [dynamic]^Simple_Model;

Entity_Union :: union {
	Player_Character,
	Enemy,
	Simple_Model,
}

entity_typeids := [3]typeid{
	typeid_of(Player_Character),
	typeid_of(Enemy),
	typeid_of(Simple_Model),
};

_add_entity :: proc(e: ^Entity) {
	switch kind in e.kind {
		case Player_Character: append(&all_Player_Character, cast(^Player_Character) e);
		case Enemy: append(&all_Enemy, cast(^Enemy) e);
		case Simple_Model: append(&all_Simple_Model, cast(^Simple_Model) e);
	}
}

_destroy_entity :: proc(e: ^Entity) {
	switch kind in e.kind {
		case Player_Character: for ep, i in all_Player_Character do if cast(^Entity) ep == e { unordered_remove(&all_Player_Character, i); break; }
		case Enemy: for ep, i in all_Enemy do if cast(^Entity) ep == e { unordered_remove(&all_Enemy, i); break; }
		case Simple_Model: for ep, i in all_Simple_Model do if cast(^Entity) ep == e { unordered_remove(&all_Simple_Model, i); break; }
	}
}

create_entity_by_type :: proc(t: typeid) -> Entity {
    e := _create_entity();

    switch t {
		case Player_Character: e.kind = Player_Character{};
		case Enemy: e.kind = Enemy{};
		case Simple_Model: e.kind = Simple_Model{};
    }

    return e;
}

