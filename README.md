<p align="center">
    <img src="misc/logo-slim.png" alt="Odin logo" style="width:65%">
    <br/>
   The Data-Oriented Language for Sane Software Development.
    <br/>
    <br/>
    <a href="https://github.com/odin-lang/odin/releases/latest">
        <img src="https://img.shields.io/github/release/odin-lang/odin.svg">
    </a>
    <a href="https://github.com/odin-lang/odin/releases/latest">
        <img src="https://img.shields.io/badge/platforms-Windows%20|%20Linux%20|%20macOS-green.svg">
    </a>
    <br>
    <a href="https://discord.com/invite/sVBPHEv">
        <img src="https://img.shields.io/discord/568138951836172421?logo=discord">
    </a>
    <a href="https://github.com/odin-lang/odin/actions">
        <img src="https://github.com/odin-lang/odin/actions/workflows/ci.yml/badge.svg?branch=master&event=push">
    </a>
</p>

## Odin Language fork, focused on safety

- The goal of this fork is to make Odin a safer language, breaking the implicit patterns from the C language and improving code readability, and making it more enjoyable to work with memory.
- I love Odin, but I don't like how it hides allocations from the user and tries to handle lots of behavior implicitly. If an allocator is invalid, there should be no fallback. A buggy code is a buggy code and should *crash*. I believe that typing one extra word is an absolute worth trade-off than losing tracking of how your memory is managed. We shouldn't hide when memory is mentioned.


- Currently, all changes are in `.odin` files. No changes were made to the `.cpp` source code, so the compiler is untouched. I'll maybe change the compiler if this would result in improvements to safety that could not be achieved by the Odin language alone.


- This is a **WIP (work-in-progress)**. Changing every single library in Odin is not easy. There will be a lot of broken code in the beginning, but the goal is a complete overhaul of safety in Odin.
- If you find something that could be improved, or it's broken, feel free to open an issue or contribute with a PR.
- As of TODAY (2025-12-14), there will be a LOT of broken things. I'm first fixing the libraries for Windows, but I'll get to the other OSs after the main changes are made.


## Main Changes

### Context

- This is the new signature for `context`:
```odin
Context :: struct {
	user_ptr:   rawptr,
	user_index: int,

	_internal: rawptr,
}
```
- Context is *only* used for interop with third-party APIs.
- Every other entry was removed and replaced with something less invasive.
- You should only care about `context` if you are aiming to interact with an external API, as follows:
```odin
import "core:fmt"

Third_Party_API :: struct {
    callback_with_limiting_signature: #type proc(),
}

your_callback_implementation :: proc() {
    my_array := cast(^[]int)context.user_ptr
    fmt.println(my_array)
        // Prints: &[4, 1, 3, 2]
}

main :: proc() {
    api := Third_Party_API{
        callback_with_limiting_signature = your_callback_implementation
    }

    my_array := []int{ 4, 1, 3, 2 }
    context.user_ptr = &my_array
    api.callback_with_limiting_signature()
}

```
- If this is not the case, `context` will serve you no purpose and can be ignored.
- The default `"odin"` calling convention should still be used for consistency and for better future third-party integrations with your codebase.


### Implicit allocations

- `context.allocator` was **removed**.

#### Before
```odin
main :: proc() {
    a := make([dynamic]int)
        // context.allocator was used implicitly.
    defer delete(a)

    b := new(int)
        // context.allocator was used implicitly.
    defer free(b)
        // context.allocator was used implicitly.
}
```

#### After
- **All** uses of allocators is enforced to be **explicit**.
- No code inside the library uses implicit allocators. 
- The signature `allocator := ` was replaced by `allocator: mem.Allocator`.
```odin
import "base:runtime"

main :: proc() {
    allocator := runtime.heap_allocator()

    a := make([dynamic]int, allocator)
        //  `make` *requires* an explicit allocator. If not complied, there will be a compile-time error.
    defer delete(a)
        // No need to be explicit about the allocator here, as a `[dynamic]` array stores the allocator.

    b := new(int, allocator)
        //  `new` *requires* an explicit allocator. If not complied, there will be a compile-time error.
    defer free(b, allocator)
        //  `free` *requires* an explicit allocator. If not complied, there will be a compile-time error.
}
```
- In this example, the `runtime.heap_allocator()` was used, which is the **same** allocator from the previous `context.allocator`. You'll have the same allocation behavior, but now the allocation has to be **explicit** and is no longer tied to the `context` system. More on that later. 


### Procedures with allocation and variadic arguments

- This is not allowed in Odin:
```odin
aprint :: proc(args: ..any, sep := " ", allocator: mem.Allocator) -> string { }
```
- `aprint` has a variadic argument (`args`), followed by an argument without a default value.
- To make this work, this change was made:
```odin
aprint :: proc(args: []any, sep := " ", allocator: mem.Allocator) -> string { }
```
- The procedure no longer supports the variadic argument.
- I also thought about these signatures:
    - Passing the `allocator` first would allow the variadic argument to exist, but this would break the convention of passing the allocator as the last parameter.
    ```odin
    aprint :: proc(allocator: mem.Allocator, args: ..any, sep := " ") -> string { }
    ```
    - Using a default value for `allocator` that would result in a panic. This is objectively a worse solution than the one I went with, as this only generates an error at runtime, while not using a default value generates an error at compile time.
    ```odin
    aprint :: proc(args: ..any, sep := " ", allocator: runtime.COMPTIME_PANIC_ALLOCATOR) -> string { }
    ```
- The solution I went with is not as ergonomic as the one from Odin, but this is a fair price to avoid an implicit allocation.

#### Before
```odin
aprint :: proc(args: ..any, sep := " ", allocator := context.allocator) -> string { }

msg := aprint(1, 2, 3, 4)
    // This used the context.allocator implicitly.
```

#### After
```odin
aprint :: proc(args: []any, sep := " ", allocator: mem.Allocator) -> string { }

msg := aprint({1, 2, 3, 4}, allocator = my_allocator)
    // The procedure now *requires* an explicit allocator. If not complied, there will be a compile-time error.
```



### Implicit allocation on change

- Before
```odin
main :: proc() {
    a: [dynamic]int
    append(&a, 1)
        // context.allocator was used implicitly to allocate `a`.
}
```
- This behavior is no longer allowed, as it only leads to confusing and buggy code. This was especially a problem when using custom allocators, but forgetting to initialize an array/map, making the data be allocated without the usage of your custom allocator.
- This now results in a runtime assertion.

- After
```odin
main :: proc() {
    a: [dynamic]int
    append(&a, 1)
        // Runtime assertion, indicating that no allocator was used for `a` and the array should be initialized. 
}
```


### Assertions

- `context.assertion_failure_proc` was **removed**.
- `runtime.assertion_failure_proc` was created to now hold the user customization of how an assertion should be.
- For clarity, `assert`, `panic`, `ensure` and `unimplemented` are now all `"contextless"` by default. The old counterparts were removed (`assert_contextless`, etc).
- Flaws from the old implementation with `context.assertion_failure_proc`:
```odin
println_any :: #force_no_inline proc "contextless" (args: ..any) {
    context = default_context()
    loop: for arg, i in args {
        assert(arg.id != nil) 
            // ^^ This assertion will *not* be the one defined by the user, but the default one from the `context = default_context()`
        if i != 0 {
            print_string(" ")
        }
        print_any_single(arg)
    }
    print_string("\n")
}
```
- Having the 'user customization' decoupled from the `context` ensures uniformity for any calling convention used. 
- *Now assertions from within `"contextless"` procedure will respect the user-defined behavior, defined in the `runtime.assertion_failure_proc`*.
- New implementation:
```odin
Assertion_Failure_Proc :: #type proc "contextless" (prefix, message: string, loc: Source_Code_Location) -> !
assertion_failure_proc: Assertion_Failure_Proc = default_assertion_failure_proc

@(disabled=ODIN_DISABLE_ASSERT)
assert :: proc "contextless" (condition: bool, message := #caller_expression(condition), loc := #caller_location) {
	if !condition {
		@(cold)
		internal :: proc "contextless" (message: string, loc: Source_Code_Location) {
			assertion_failure_proc("runtime assertion", message, loc)
		}
		internal(message, loc)
	}
}
```
- The `runtime.assertion_failure_proc` can be changed by the user.
- The default for `context.assertion_failure_proc` and `runtime.assertion_failure_proc` is the same. If you haven't changed the old `context.assertion_failure_proc` to anything different, the behavior will be the same. 


### Logger

- TODO


### Removal of Random Number Generator

- TODO


### No uses of `@(init)` and `@(fini)`

- TODO


### Temporary Allocations

- `context.temp_allocator` will be **removed**.
- TODO


### The `core:os` was replaced by `core:os/os2`

- The `core:os` library was **removed**. 
- There are plans for Odin to replace the libraries in 2026, but as I was changing the codebase so much for safety reasons, I decided to rush the replacement, as the old `core:os` had a lot of implicit behavior everywhere, and `os2` is a far better library.
- If you see `import "core:os"`, this refers to the new `os2`, simply renamed to `os`.

