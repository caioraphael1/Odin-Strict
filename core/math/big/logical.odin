package math_big

import "core:mem"
/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	An arbitrary precision mathematics implementation in Odin.
	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

	This file contains logical operations like `and`, `or` and `xor`.
*/

/*
	The `and`, `or` and `xor` binops differ in two lines only.
	We could handle those with a switch, but that adds overhead.

	TODO: Implement versions that take a DIGIT immediate.
*/

/*
	2's complement `and`, returns `dest = a & b;`
*/
int_bit_and :: proc(dest, a, b: ^Int, allocator: mem.Allocator) -> (err: Error) {
	assert_if_nil(dest, a, b)

	internal_clear_if_uninitialized(a, b) or_return
	return #force_inline internal_int_and(dest, a, b, allocator)
}
bit_and :: proc { int_bit_and, }

/*
	2's complement `or`, returns `dest = a | b;`
*/
int_bit_or :: proc(dest, a, b: ^Int, allocator: mem.Allocator) -> (err: Error) {
	assert_if_nil(dest, a, b)

	internal_clear_if_uninitialized(a, b) or_return
	return #force_inline internal_int_or(dest, a, b, allocator)
}
bit_or :: proc { int_bit_or, }

/*
	2's complement `xor`, returns `dest = a ^ b;`
*/
int_bit_xor :: proc(dest, a, b: ^Int, allocator: mem.Allocator) -> (err: Error) {
	assert_if_nil(dest, a, b)

	internal_clear_if_uninitialized(a, b) or_return
	return #force_inline internal_int_xor(dest, a, b, allocator)
}
bit_xor :: proc { int_bit_xor, }

/*
	dest = ~src
*/
int_bit_complement :: proc(dest, src: ^Int, allocator: mem.Allocator) -> (err: Error) {
	/*
		Check that `src` and `dest` are usable.
	*/
	assert_if_nil(dest, src)

	internal_clear_if_uninitialized(dest, src) or_return
	return #force_inline internal_int_complement(dest, src, allocator)
}
bit_complement :: proc { int_bit_complement, }

/*
	quotient, remainder := numerator >> bits;
	`remainder` is allowed to be passed a `nil`, in which case `mod` won't be computed.
*/
int_shrmod :: proc(quotient, remainder, numerator: ^Int, bits: int, allocator: mem.Allocator) -> (err: Error) {
	assert_if_nil(quotient, numerator)

	if err = internal_clear_if_uninitialized(quotient, numerator);  err != nil { return err }
	return #force_inline internal_int_shrmod(quotient, remainder, numerator, bits, allocator)
}
shrmod :: proc { int_shrmod, }

int_shr :: proc(dest, source: ^Int, bits: int, allocator: mem.Allocator) -> (err: Error) {
	return #force_inline shrmod(dest, nil, source, bits, allocator)
}
shr :: proc { int_shr, }

/*
	Shift right by a certain bit count with sign extension.
*/
int_shr_signed :: proc(dest, src: ^Int, bits: int, allocator: mem.Allocator) -> (err: Error) {
	assert_if_nil(dest, src)

	internal_clear_if_uninitialized(dest, src) or_return
	return #force_inline internal_int_shr_signed(dest, src, bits, allocator)
}

shr_signed :: proc { int_shr_signed, }

/*
	Shift left by a certain bit count.
*/
int_shl :: proc(dest, src: ^Int, bits: int, allocator: mem.Allocator) -> (err: Error) {
	assert_if_nil(dest, src)

	internal_clear_if_uninitialized(dest, src) or_return
	return #force_inline internal_int_shl(dest, src, bits, allocator)
}
shl :: proc { int_shl, }
