package mem_virtual

import "core:sys/posix"

_reserve :: proc(size: uint) -> (data: []byte, err: Allocator_Error) {
	result := posix.mmap(nil, size, {}, {.ANONYMOUS, .PRIVATE})
	if result == posix.MAP_FAILED {
		assert(posix.errno() == .ENOMEM)
		return nil, .Out_Of_Memory
	}

	return ([^]byte)(uintptr(result))[:size], nil
}

_decommit :: proc(data: rawptr, size: uint) {
	MADV_FREE :: 6

	posix.mprotect(data, size, {})
	posix.posix_madvise(data, size, transmute(posix.MAdvice)i32(MADV_FREE))
}
