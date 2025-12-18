#+build !amd64
package chacha20_simd256

import "base:intrinsics"
import "core:crypto/_chacha20"

is_performant :: proc() -> bool {
	return false
}

stream_blocks :: proc(ctx: ^_chacha20.Context, dst, src: []byte, nr_blocks: int) {
	panic("crypto/chacha20: simd256 implementation unsupported")
}

hchacha20 :: proc(dst, key, iv: []byte) {
	panic("crypto/chacha20: simd256 implementation unsupported")
}
