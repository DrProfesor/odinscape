package entity

all_Player_Character: [dynamic]^Player_Character;
all_Enemy: [dynamic]^Enemy;

entity_typeids := [2]typeid{
	typeid_of(Player_Character),
	typeid_of(Enemy),
};

_add_entity :: proc(e: ^Entity) {
	switch kind in e.kind {
		case Player_Character: append(&all_Player_Character, cast(^Player_Character) e);
		case Enemy: append(&all_Enemy, cast(^Enemy) e);
	}
}

_destroy_entity :: proc(e: ^Entity) {
	switch kind in e.kind {
		case Player_Character: for ep, i in all_Player_Character do if cast(^Entity) ep == e { unordered_remove(&all_Player_Character, i); break; }
		case Enemy: for ep, i in all_Enemy do if cast(^Entity) ep == e { unordered_remove(&all_Enemy, i); break; }
	}
}

