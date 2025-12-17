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
	arena_temp:      runtime.Arena_Temp,
	loc:             runtime.Source_Code_Location,
}

@(deferred_out=temp_allocator_temp_end)
TEMP_ALLOCATOR_GUARD :: #force_inline proc(collisions: []runtime.Allocator, loc := #caller_location) -> Temp_Allocator {
	assert(len(collisions) <= MAX_TEMP_ARENA_COLLISIONS, "Maximum collision count exceeded. MAX_TEMP_ARENA_COUNT must be increased!")

    // Get an arena with no collisions.
	arena_with_no_collisions: ^runtime.Arena
	loop_outer: for i in 0..<MAX_TEMP_ARENA_COUNT {
		arena_with_no_collisions = &global_default_temp_allocator_arenas[i]
		for col in collisions {
            // Collided with an arena.
			if col.data == arena_with_no_collisions {
				arena_with_no_collisions = nil
                continue loop_outer
			}
		}

        // Arena with no collisions found.
        break loop_outer
	}
	assert(arena_with_no_collisions != nil)

	if arena_with_no_collisions.backing_allocator.procedure == nil {
		arena_with_no_collisions.backing_allocator = runtime.general_allocator
            // TODO(caio): I should remove this implicit assignment somehow.
	}
	return { 
        arena      = arena_with_no_collisions, 
        allocator  = runtime.arena_allocator(arena_with_no_collisions), 
        arena_temp = runtime.arena_temp_begin(arena_with_no_collisions, loc),
        loc        = loc,
    }
}

	
temp_allocator_temp_end :: proc(temp: Temp_Allocator) {
	runtime.arena_temp_end(temp.arena_temp, temp.loc)
}

@(deferred_out=runtime.arena_temp_end)
TEMP_ALLOCATOR_SCOPE :: proc(arena_temp: Temp_Allocator, loc := #caller_location) -> (runtime.Arena_Temp, runtime.Source_Code_Location) {
	return runtime.arena_temp_begin(arena_temp.arena), loc
}
