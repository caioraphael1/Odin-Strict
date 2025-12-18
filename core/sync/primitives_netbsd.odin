#+private
package sync

foreign import libc "system:c"

foreign libc {
	_lwp_self :: proc "c" () -> i32 ---
}

_current_thread_id :: proc() -> int {
	return int(_lwp_self())
}
