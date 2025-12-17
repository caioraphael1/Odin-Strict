// Multi-threading operations to spawn threads and thread pools.
package thread

import "base:runtime"
import "core:mem"
import "base:intrinsics"

_ :: intrinsics

/*
Value, specifying whether `core:thread` functionality is available on the
current platform.
*/
IS_SUPPORTED :: _IS_SUPPORTED

/*
Type for a procedure that will be run in a thread, after that thread has been
started.
*/
Thread_Proc :: #type proc(^Thread)

/*
Maximum number of user arguments for polymorphic thread procedures.
*/
MAX_USER_ARGUMENTS :: 8

/*
Type representing the state/flags of the thread.
*/
Thread_State :: enum u8 {
	Started,
	Joined,
	Done,
	Self_Cleanup,
}

/*
Type representing a thread handle and the associated with that thread data.
*/
Thread :: struct {
	using specific:     Thread_Os_Specific,
	flags:              bit_set[Thread_State; u8],

	// Thread ID. Depending on the platform, may start out as 0 (zero) until the thread
	// has had a chance to run.
	id:                 int,

	// The thread procedure.
	procedure:          Thread_Proc,

	// User-supplied pointer, that will be available to the thread once it is
	// started. Should be set after the thread has been created, but before
	// it is started.
	data:               rawptr,

	// User-supplied integer, that will be available to the thread once it is
	// started. Should be set after the thread has been created, but before
	// it is started.
	user_index:         int,

	// User-supplied array of arguments, that will be available to the thread,
	// once it is started. Should be set after the thread has been created,
	// but before it is started.
	user_args:          [MAX_USER_ARGUMENTS]rawptr,

	// The allocator used to allocate data for the thread.
	creation_allocator: mem.Allocator,
}

when IS_SUPPORTED {
	#assert(size_of(Thread{}.user_index) == size_of(uintptr))
}

/*
Type representing priority of a thread.
*/
Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

/*
Create a thread in a suspended state with the given priority.

This procedure creates a thread that will be set to run the procedure
specified by `procedure` parameter with a specified priority. The returned
thread will be in a suspended state, until `start()` procedure is called.

To start the thread, call `start()`. Also the `create_and_start()`
procedure can be called to create and start the thread immediately.
*/
create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal, allocator: mem.Allocator) -> ^Thread {
	return _create(procedure, priority, allocator)
}

/*
Start a suspended thread.
*/
start :: proc(thread: ^Thread) {
	_start(thread)
}


/*
Run a procedure on a different thread.

This procedure runs the given procedure on another thread.  The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed.

**Do not** dereference the `^Thread` pointer, if this flag is specified.
That includes calling `join`, which needs to dereference ^Thread`.
*/
create_and_start :: proc(fn: proc(), priority := Thread_Priority.Normal, self_cleanup := false, allocator: mem.Allocator) -> (t: ^Thread) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc())t.data
		fn()
	}
	if t = create(thread_proc, priority, allocator); t == nil {
		return
	}
	t.data = rawptr(fn)
	if self_cleanup {
		intrinsics.atomic_or(&t.flags, {.Self_Cleanup})
	}
	start(t)
	return t
}


/*
Wait for the thread to finish work.
*/
join :: proc(thread: ^Thread) {
	_join(thread)
}

/*
Wait for all threads to finish work, and closes their handles.
*/
join_multiple :: proc(threads: ..^Thread) {
	_join_multiple(..threads)
}

/*
Wait for the thread to finish and free all data associated with it.
join + free.
*/
destroy :: proc(thread: ^Thread) {
	_destroy(thread)
}

/*
Forcibly terminate/cancel a running thread.
*/
terminate :: proc(thread: ^Thread, exit_code: int) {
	_terminate(thread, exit_code)
}

/*
Check if the thread has finished work.
*/
is_done :: proc(thread: ^Thread) -> bool {
	return _is_done(thread)
}

/*
Yield the execution of the current thread to another OS thread or process.
*/
yield :: proc() {
	_yield()
}

