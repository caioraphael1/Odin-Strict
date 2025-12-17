#+private
package os2

import "base:runtime"
import "core:sys/darwin"

_copy_directory_all_native :: proc(dst, src: string, dst_perm := 0o755) -> (err: Error) {
	runtime.TEMP_ALLOCATOR_TEMP_GUARD()

	csrc := clone_to_cstring(src, runtime.temp_allocator) or_return
	cdst := clone_to_cstring(dst, runtime.temp_allocator) or_return

	if darwin.copyfile(csrc, cdst, nil, darwin.COPYFILE_ALL + {.RECURSIVE}) < 0 {
		err = _get_platform_error()
	}

	return
}
