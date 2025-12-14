#+build js
#+private
package timezone

import "core:time/datetime"
import "base:runtime"

local_tz_name :: proc(allocator: runtime.Allocator) -> (name: string, success: bool) {
	return
}

_region_load :: proc(_reg_str: string, allocator: runtime.Allocator) -> (out_reg: ^datetime.TZ_Region, success: bool) {
	return nil, true
}
