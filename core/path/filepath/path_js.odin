package filepath

import "base:runtime"

import "core:strings"
import "core:mem"

SEPARATOR :: '/'
SEPARATOR_STRING :: `/`
LIST_SEPARATOR :: ':'

is_reserved_name :: proc(path: string) -> bool {
	return false
}

is_abs :: proc(path: string) -> bool {
	return strings.has_prefix(path, "/")
}

abs :: proc(path: string, allocator: mem.Allocator) -> (string, bool) {
	if is_abs(path) {
		return strings.clone(string(path), allocator), true
	}

	return path, false
}

join :: proc(elems: []string, allocator: mem.Allocator) -> (joined: string, err: runtime.Allocator_Error) #optional_allocator_error {
	for e, i in elems {
		if e != "" {
			runtime.TEMP_ALLOCATOR_TEMP_GUARD(allocator)
			p := strings.join(elems[i:], SEPARATOR_STRING, runtime.temp_allocator) or_return
			return clean(p, allocator)
		}
	}
	return "", nil
}
