package wgpu

import "base:runtime"


g_ctx: runtime.Context


@(private="file", export)
wgpu_alloc :: proc "contextless" (size: i32) -> [^]byte {
	context = g_ctx
	bytes, err := runtime.mem_alloc(int(size), 16)
	assert(err == nil, "wgpu_alloc failed")
	return raw_data(bytes)
}

@(private="file", export)
wgpu_free :: proc "contextless" (ptr: rawptr) {
	context = g_ctx
	err := free(ptr)
	assert(err == nil, "wgpu_free failed")
}
