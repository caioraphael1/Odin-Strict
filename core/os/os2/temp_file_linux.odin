#+private
package os2

import "base:runtime"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	runtime.TEMP_ALLOCATOR_TEMP_GUARD(allocator)
	tmpdir := get_env("TMPDIR", runtime.temp_allocator)
	if tmpdir == "" {
		tmpdir = "/tmp"
	}
	return clone_string(tmpdir, allocator)
}
