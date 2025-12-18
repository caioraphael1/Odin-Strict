#+private
package sync

import "core:sys/haiku"

_current_thread_id :: proc() -> int {
	return int(haiku.find_thread(nil))
}
