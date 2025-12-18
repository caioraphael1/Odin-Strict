#+private
#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
package mem_virtual

import os "core:os/os2"

_reserve :: proc(size: uint) -> (data: []byte, err: Allocator_Error) {
	return nil, nil
}

_commit :: proc(data: rawptr, size: uint) -> Allocator_Error {
	return nil
}

_decommit :: proc(data: rawptr, size: uint) {
}

_release :: proc(data: rawptr, size: uint) {
}

_protect :: proc(data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	return false
}

_platform_memory_init :: proc() {
}

_map_file :: proc(fd: ^os.File, size: i64, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	return nil, .Map_Failure
}
