#+private
package os2

import "base:runtime"

import "core:sync"
import "core:sys/wasm/wasi"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_is_path_separator :: proc(c: byte) -> bool {
	return c == _Path_Separator
}

_mkdir :: proc(name: string, perm: int) -> Error {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return .Invalid_Path
	}

	return _get_platform_error(wasi.path_create_directory(dir_fd, relative))
}

_mkdir_all :: proc(path: string, perm: int) -> Error {
	internal_mkdir_all :: proc(path: string) -> Error {
		dir, file := split_path(path)
		if file != path && dir != "/" {
			if len(dir) > 1 && dir[len(dir) - 1] == '/' {
				dir = dir[:len(dir) - 1]
			}
			internal_mkdir_all(dir) or_return
		}

		err := _mkdir(path, 0)
		if err == .Exist { err = nil }
		return err
	}

	if path == "" {
		return .Invalid_Path
	}

	runtime.TEMP_ALLOCATOR_TEMP_GUARD()

	if exists(path) {
		return .Exist
	}

	clean_path := clean_path(path, runtime.temp_allocator) or_return
	return internal_mkdir_all(clean_path)
}

_remove_all :: proc(path: string) -> (err: Error) {
	//  PERF: this works, but wastes a bunch of memory using the read_directory_iterator API
	// and using open instead of wasi fds directly.
	{
		dir := open(path) or_return
		defer close(dir)

		iter := read_directory_iterator_create(dir)
		defer read_directory_iterator_destroy(&iter)

		for fi in read_directory_iterator(&iter) {
			_ = read_directory_iterator_error(&iter) or_break

			if fi.type == .Directory {
				_remove_all(fi.fullpath) or_return
			} else {
				remove(fi.fullpath) or_return
			}
		}

		_ = read_directory_iterator_error(&iter) or_return
	}

	return remove(path)
}

_working_dir: struct {
    path:      string,
    allocator: runtime.Allocator,
    mutex:     sync.Mutex,
}

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	sync.guard(&_working_dir_mutex)
    _working_dir.allocator = allocator
	return clone_string(_working_dir.path if _working_dir.path != "" else "/", _working_dir.allocator)
}

_set_working_directory :: proc(dir: string, allocator: runtime.Allocator) -> (err: Error) {
	sync.guard(&_working_dir.mutex)

	if dir == _working_dir.path {
		return
	}

	if _working_dir.path != "" {
		delete(_working_dir.path, _working_dir.allocator)
        _working_dir.allocator = {}
	}

	_working_dir.path = clone_string(dir, allocator) or_return
    _working_dir.allocator = allocator
	return
}

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	if len(args) <= 0 {
		return clone_string("/", allocator)
	}

	arg := args[0]
	if len(arg) > 0 && (arg[0] == '.' || arg[0] == '/') {
		return clone_string(arg, allocator)
	}

	return concatenate({"/", arg}, allocator)
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	return "", .Unsupported
}
