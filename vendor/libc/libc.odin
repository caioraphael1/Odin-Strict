package odin_libc

import "base:runtime"

import "core:mem"

g_ctx:       runtime.Context
g_allocator: mem.Compat_Allocator

// @@init don't care
init_context :: proc() {
	// Wrapping the allocator with the mem.Compat_Allocator so we can
	// mimic the realloc semantics.
	mem.compat_allocator_init(&g_allocator, g_ctx.allocator)
	// g_ctx.allocator = mem.compat_allocator(&g_allocator)
}
