package editor

import "core:mem"
import "core:fmt"

import "shared:wb/logging"

LARGEST_MEMORY_ACTION :: 1024;

action_stack: [dynamic]Action; // stack holding actions that have been done
action_marker := 0;

// Usage: 
// {
// 	  PUSH_MEMORY_ACTION(&data, typeid_of(data));
// 	  do your thing
// }
@(deferred_out=commit_memory_action)
PUSH_MEMORY_ACTION :: proc(target: rawptr, tid: typeid) -> Memory_Action {
	return _create_memory_action(target, tid);
}

//
//
create_memory_action :: proc(target: ^$T) -> Memory_Action {
	return _create_memory_action(target, typeid_of(T));
}

//
//
commit_memory_action :: proc(_action: Memory_Action) {
	action := _action;
	mem.copy(&action.post_state, action.target, action.len);

	ok := reserve(&action_stack, len(action_stack)+1);
	assert(ok);
	
	_push_action(action);
}

//
//
create_and_commit_proc_action :: proc(undo, redo: proc(rawptr), user_data: ^$T) {
	ti  := type_info_of(tid);
	
	assert(ti.size <= LARGEST_MEMORY_ACTION, fmt.tprint("Userdata too large for proc action:", ti.size));
	
	action := Proc_Action { {---}, ti.size, undo, redo };
	_push_action(action);
	mem_copy(&action_stack[action_marker-1], user_data, ti.size);
	action.redo(user_data);
}

_push_action :: proc(action: Action) {
	raw_array := cast(^mem.Raw_Dynamic_Array)&action_stack;
	raw_array.len = action_marker + 1;
	action_stack[action_marker] = action;
	action_marker += 1;
}

_create_memory_action :: proc(target: rawptr, tid: typeid) -> Memory_Action {
	ti  := type_info_of(tid);

	assert(ti.size <= LARGEST_MEMORY_ACTION, fmt.tprint("Memory action too big:", ti.size));

	action: Memory_Action = ---;
	action.target = target;
	action.len = ti.size;

	mem.copy(&action.prior_state, target, ti.size);

	return action;
}

//
undo :: proc() {
	if action_marker <= 0 do return;

	action_marker -= 1;

	switch action in &action_stack[action_marker] {
		case Memory_Action: {
			mem.copy(action.target, &action.prior_state, action.len);
		}
		case Proc_Action: {
			action.undo(&action.user_data);
		}
	}
}

//
redo :: proc() {
	if action_marker >= len(action_stack) do return;

	switch action in &action_stack[action_marker] {
		case Memory_Action: {
			mem_action := action;
			mem.copy(mem_action.target, &mem_action.post_state, mem_action.len);
		}
		case Proc_Action: {
			action.redo(&action.user_data);
		}
	}
	action_marker += 1;
}

Action :: union {
	Memory_Action,
	Proc_Action,
}

Proc_Action :: struct {
	user_data: [LARGEST_MEMORY_ACTION]byte,
	data_len:  int,
	undo:    proc(rawptr),
	redo:    proc(rawptr),
}

Memory_Action :: struct {
	target: rawptr,
	prior_state: [LARGEST_MEMORY_ACTION]byte, // may want to turn this to a rawptr?
	post_state:  [LARGEST_MEMORY_ACTION]byte, // may want to turn this to a rawptr?
	len: int,
}