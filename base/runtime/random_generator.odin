package runtime

import "base:intrinsics"


Random_Generator_Mode :: enum {
	Read,
	Reset,
	Query_Info,
}

Random_Generator_Query_Info_Flag :: enum u32 {
	Cryptographic,
	Uniform,
	External_Entropy,
	Resettable,
}
Random_Generator_Query_Info :: distinct bit_set[Random_Generator_Query_Info_Flag; u32]

Random_Generator_Proc :: #type proc(data: rawptr, mode: Random_Generator_Mode, p: []byte)

Random_Generator :: struct {
	procedure: Random_Generator_Proc,
	data:      rawptr,
}

global_random_generator := Random_Generator{
    procedure = default_random_generator_proc,
    data      = nil,
}

@(require_results)
random_generator_read_bytes :: proc(rg: Random_Generator, p: []byte) -> bool {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Read, p)
		return true
	}
	return false
}

@(require_results)
random_generator_read_ptr :: proc(rg: Random_Generator, p: rawptr, len: uint) -> bool {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Read, ([^]byte)(p)[:len])
		return true
	}
	return false
}

@(require_results)
random_generator_query_info :: proc(rg: Random_Generator) -> (info: Random_Generator_Query_Info) {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Query_Info, ([^]byte)(&info)[:size_of(info)])
	}
	return
}


random_generator_reset_bytes :: proc(rg: Random_Generator, p: []byte) {
	if rg.procedure != nil {
		rg.procedure(rg.data, .Reset, p)
	}
}

random_generator_reset_u64 :: proc(rg: Random_Generator, p: u64) {
	if rg.procedure != nil {
		p := p
		rg.procedure(rg.data, .Reset, ([^]byte)(&p)[:size_of(p)])
	}
}
