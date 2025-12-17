package os2

import "base:runtime"


@(private="file", thread_local) global_default_temp_allocator_arenas: [MAX_TEMP_ARENA_COUNT]runtime.Arena

// @@fini
fini_temp_allocators :: proc() {
	for &arena in global_default_temp_allocator_arenas {
		runtime.arena_destroy(&arena)
	}
	global_default_temp_allocator_arenas = {}
}


@(private="file") MAX_TEMP_ARENA_COUNT      :: 2
@(private="file") MAX_TEMP_ARENA_COLLISIONS :: MAX_TEMP_ARENA_COUNT - 1

Temp_Allocator :: struct {
	using arena:     ^runtime.Arena,
	using allocator: runtime.Allocator,
	tmp:             runtime.Arena_Temp,
	loc:             runtime.Source_Code_Location,
}
	
TEMP_ALLOCATOR_GUARD_END :: proc(temp: Temp_Allocator) {
	runtime.arena_temp_end(temp.tmp, temp.loc)
}

@(deferred_out=TEMP_ALLOCATOR_GUARD_END)
TEMP_ALLOCATOR_GUARD :: #force_inline proc(collisions: []runtime.Allocator, loc := #caller_location) -> Temp_Allocator {
	assert(len(collisions) <= MAX_TEMP_ARENA_COLLISIONS, "Maximum collision count exceeded. MAX_TEMP_ARENA_COUNT must be increased!")
	good_arena: ^runtime.Arena
	for i in 0..<MAX_TEMP_ARENA_COUNT {
		good_arena = &global_default_temp_allocator_arenas[i]
		for c in collisions {
			if good_arena == c.data {
				good_arena = nil
			}
		}
		if good_arena != nil {
			break
		}
	}
	assert(good_arena != nil)
	if good_arena.backing_allocator.procedure == nil {
		good_arena.backing_allocator = runtime.general_allocator
            // TODO(caio): I should remove this implicit assignment somehow.
	}
	tmp := runtime.arena_temp_begin(good_arena, loc)
	return { good_arena, runtime.arena_allocator(good_arena), tmp, loc }
}


@(deferred_out=runtime.arena_temp_end)
TEMP_ALLOCATOR_SCOPE :: proc(tmp: Temp_Allocator, loc := #caller_location) -> (runtime.Arena_Temp, runtime.Source_Code_Location) {
	return runtime.arena_temp_begin(tmp.arena), loc
}
