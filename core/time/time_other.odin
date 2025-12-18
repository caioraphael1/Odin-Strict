#+private
#+build !essence
#+build !js
#+build !linux
#+build !openbsd
#+build !freebsd
#+build !netbsd
#+build !darwin
#+build !wasi
#+build !windows
#+build !orca
#+build !haiku
package time

_IS_SUPPORTED :: false

_now :: proc() -> Time {
	return {}
}

_sleep :: proc(d: Duration) {
}

_tick_now :: proc() -> Tick {
	// mul_div_u64 :: proc(val, num, den: i64) -> i64 {
	// 	q := val / den
	// 	r := val % den
	// 	return q * num + r * num / den
	// }
	return {}
}

_yield :: proc() {
}
