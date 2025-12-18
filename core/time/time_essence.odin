#+private
package time

import "core:sys/es"

_IS_SUPPORTED :: true

_now :: proc() -> Time {
	// TODO Replace once there's a proper time API.
	return Time{_nsec = i64(es.TimeStampMs() * 1e6)}
}

_sleep :: proc(d: Duration) {
	es.Sleep(u64(d/Millisecond))
}

_tick_now :: proc() -> Tick {
	return Tick{_nsec = i64(es.TimeStampMs() * 1e6)}
}
