#+build !js
package wasm_js_interface

import "base:runtime"


get_element_value_string :: proc(id: string, buf: []byte) -> string {
	panic("vendor:wasm/js not supported on non JS targets")
}


get_element_min_max :: proc(id: string) -> (min, max: f64) {
	panic("vendor:wasm/js not supported on non JS targets")
}


Rect :: struct {
	x, y, width, height: f64,
}

get_bounding_client_rect :: proc(id: string) -> (rect: Rect) {
	panic("vendor:wasm/js not supported on non JS targets")
}

window_get_rect :: proc() -> (rect: Rect) {
	panic("vendor:wasm/js not supported on non JS targets")
}

window_get_scroll :: proc() -> (x, y: f64) {
	panic("vendor:wasm/js not supported on non JS targets")
}
