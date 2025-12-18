package runtime

/*
Note:
This allocator needs to be manually initialized by the user.
*/


// Temp Allocator
when ODIN_ARCH == .i386 && ODIN_OS == .Windows {
    // Thread-local storage is problematic on Windows i386
    temp_allocator: Allocator
    temp_allocator_arena: Arena
} else {
    @(thread_local) temp_allocator: Allocator
    @(thread_local) temp_allocator_arena: Arena
}

temp_allocator_init :: proc(size: uint, backing_temp_allocator: Allocator) {
    // Temp Allocator Arena, using the Backing Temp Allocator
    err := arena_init(&temp_allocator_arena, 0, backing_temp_allocator)
    assert(err == nil, "Failure initializing the arena")

    // Temp Allocator, using the Temp Allocator Arena
    temp_allocator = arena_allocator(&temp_allocator_arena)
}

temp_allocator_destroy :: proc() {
    arena_destroy(&temp_allocator_arena)
}

@(deferred_out=arena_temp_end)
TEMP_ALLOCATOR_TEMP_GUARD :: #force_inline proc(collision: Allocator = {}, loc := #caller_location) -> (Arena_Temp, Source_Code_Location) {
	if collision == temp_allocator {
		return {}, loc
	}
    return arena_temp_begin(&temp_allocator_arena, loc), loc
}
