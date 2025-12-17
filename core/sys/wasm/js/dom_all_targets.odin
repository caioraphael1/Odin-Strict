#+build !js
package wasm_js_interface

import "base:runtime"


get_element_value_string :: proc "contextless" (id: string, buf: []byte) -> string {
	panic("vendor:wasm/js not supported on non JS targets")
}


get_element_min_max :: proc "contextless" (id: string) -> (min, max: f64) {
	panic("vendor:wasm/js not supported on non JS targets")
}


Rect :: struct {
	x, y, width, height: f64,
}

get_bounding_client_rect :: proc "contextless" (id: string) -> (rect: Rect) {
	panic("vendor:wasm/js not supported on non JS targets")
}

window_get_rect :: proc "contextless" () -> (rect: Rect) {
	panic("vendor:wasm/js not supported on non JS targets")
}

window_get_scroll :: proc "contextless" () -> (x, y: f64) {
	panic("vendor:wasm/js not supported on non JS targets")
}
