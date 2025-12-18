#+private
#+build wasm32, wasm64p32
package sync

import "base:intrinsics"
import "core:time"

// NOTE: because `core:sync` is in the dependency chain of a lot of the core packages (mostly through `core:mem`)
// without actually calling into it much, I opted for a runtime panic instead of a compile error here.

_futex_wait :: proc(f: ^Futex, expected: u32) -> bool {
	when !intrinsics.has_target_feature("atomics") {
		panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		_ = intrinsics.wasm_memory_atomic_wait32((^u32)(f), expected, -1)
		return true
	}
}

_futex_wait_with_timeout :: proc(f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	when !intrinsics.has_target_feature("atomics") {
		panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		s := intrinsics.wasm_memory_atomic_wait32((^u32)(f), expected, i64(duration))
		return s != 2
	}
}

_futex_signal :: proc(f: ^Futex) {
	when !intrinsics.has_target_feature("atomics") {
		panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		_ = intrinsics.wasm_memory_atomic_notify32((^u32)(f), 1)
	}
}

_futex_broadcast :: proc(f: ^Futex) {
	when !intrinsics.has_target_feature("atomics") {
		panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		_ = intrinsics.wasm_memory_atomic_notify32((^u32)(f), max(u32))
	}
}

