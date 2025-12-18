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

# Odin Language fork focused on exploring language design, memory safety, and other completely subjective things

- One of the goals of this fork is to make Odin a safer language, breaking the implicit patterns from the C language, improving code readability, and making it more enjoyable to work with memory.
- I love Odin, but I don't like how it hides allocations from the user and tries to handle lots of behavior implicitly. If an allocator is invalid, there should be no fallback. A buggy code is a buggy code and should *crash*. Typing one extra word is an absolute worth trade-off over losing track of how your memory is managed. We shouldn't hide when memory is mentioned.
- Besides that, I also changed a lot of things I consider subjective. I'm taking this as an experiment around language design, as I think it's fun.
- Feel free to use at your own discretion. That might be a **LOT** of things you don't agree with. I went far enough to remove libraries I won't use, so this is not really for public use, but I decided to keep this as a public fork so I could share a little bit of some of my design choices. 

- Currently, all changes are in `.odin` files. No changes were made to the `.cpp` source code, so the compiler is untouched. Maybe I'll change the compiler if this would result in improvements that could not be achieved by the Odin language alone.

<br>

# Main Changes

## Context

- This is the new signature for `context`:
```odin
Context :: struct {
	user_ptr:   rawptr,
	user_index: int,

	_internal: rawptr,
}
```
- Also, `runtime.default_context()` was removed. If you want a blank context, just use `context = {}`.
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

<br>

## Implicit allocations with `context.allocator`

- `context.allocator` was **removed**.

### Before
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

### After
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


<br>

## Implicit allocation on change

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

<br>

## Procedures that allocate, that also use variadic arguments

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

### Before
```odin
aprint :: proc(args: ..any, sep := " ", allocator := context.allocator) -> string { }

msg := aprint(1, 2, 3, 4)
    // This used the context.allocator implicitly.
```

### After
```odin
aprint :: proc(args: []any, sep := " ", allocator: mem.Allocator) -> string { }

msg := aprint({1, 2, 3, 4}, allocator = my_allocator)
    // The procedure now *requires* an explicit allocator. If not complied, there will be a compile-time error.
```


<br>


## No uses of `@(init)` and `@(fini)`

- `_startup_runtime` and `_cleanup_runtime` were **removed**.
- This means that `@init` and `@fini` no longer work and have to be manually called.
- Patterns like `a: T = b()` no longer work as well; I've only found this pattern inside the `core:os/os2/process.odin` for `args := get_args()` in the global scope.
- I wish the using these annotations or calling a function in the global scope would be a compiler error, but for now this is not the case and you have to unsure this doesn't happen. If it does, the operation will simply be ignored by the compiler.
- Check this [Proposal](https://github.com/odin-lang/Odin/discussions/5524) to know more.
- Check [Odin#Entry Point](https://caioraphael1.github.io/studies/Low-Level%20Systems/Odin/Odin.html#entry-point) to know more.


<br>

## Library `core/os` and `core:os/os2`

- The `core:os` library was **removed**, replaced by `core:os/os2`.
- There are plans for Odin to replace the libraries in 2026, but as I was changing the codebase so much for safety reasons, I decided to rush the replacement, as the old `core:os` had a lot of implicit behavior everywhere, and `os2` is a far better library.
- If you see `import "core:os"`, this refers to the new `os2`, simply renamed to `os`.

<br>

- The `core:os/os2` no longer allocates anything implicitly inside its library. All allocators defined in this library were removed, and now every allocation uses a user-defined allocator; you can pass in a `runtime.heap_allocator` if you want the exact previous behavior.


<br>

## Temporary Allocations

- `runtime.default_temp_allocator()` was **removed**, replaced by `runtime.temp_allocator`.
- The `context.temp_allocator` *already was a thread-local variable* in Odin, but now this behavior is clear.
- The `runtime.temp_allocator` has to be initialized manually.
- There was an overhaul in the default allocators section inside the runtime.


<br>

## Library `core:thread`

- As for the removal of `@init` and `@fini`, as well as an overhaul of temporary allocations, I decided to remove the responsibility of the `core:thread` library to manage temporary allocations.
- The user should be responsible for managing the `runtime.temp_allocator`'s lifetime. This is done exactly the same way as for the main thread:
```odin
runtime.temp_allocator_init(0, backing_temp_allocator)
defer runtime.temp_allocator_destroy()
```
- The `backing_temp_allocator` here could be any allocator. If you want the same behavior as the previous `context.temp_allocator`, just use `runtime.heap_allocator()` as the `backing_temp_allocator`.


<br>

## Overall on implicit allocations

- After all the changes, there are **NO** implicit allocations with `runtime.heap_allocator` / `context.allocator` (removed) / `os2.heap_allocator` (removed) / `os2.file_allocator` (removed) anywhere in the Odin libraries.
- The `runtime.temp_allocator` (previous `context.temp_allocator`) still does implicit allocations; after testing with this, I decided to keep it as implicit, as it was a lot of trouble having to pass this allocator in every one of its VAST uses.
- This is the **ONLY** code inside all Odin libraries that refers to implicit allocations, located on `base:runtime/default_temp_allocator.odin`.
```odin
// Temp Allocator
when ODIN_ARCH == .i386 && ODIN_OS == .Windows {
    // Thread-local storage is problematic on Windows i386
    temp_allocator: Allocator
    @(private="file") temp_allocator_arena: Arena
} else {
    @(thread_local) temp_allocator: Allocator
    @(thread_local, private="file") temp_allocator_arena: Arena
}

temp_allocator_init :: proc(size: uint, backing_temp_allocator: Allocator) {
    // Temp Allocator Arena, using the Backing Temp Allocator
    err := arena_init(&temp_allocator_arena, 0, backing_temp_allocator)
    assert(err == nil, "Failure initializing the arena")

    // Temp Allocator, using the Temp Allocator Arena
    temp_allocator = arena_allocator(&temp_allocator_arena)
}

temp_allocator_destroy :: proc() {
    arena_destroy(&temp_allocator_arena)
}

@(deferred_out=arena_temp_end)
TEMP_ALLOCATOR_TEMP_GUARD :: #force_inline proc(collision: Allocator = {}, loc := #caller_location) -> (Arena_Temp, Source_Code_Location) {
	if collision == temp_allocator {
		return {}, loc
	}
    return arena_temp_begin(&temp_allocator_arena, loc), loc
}
```

<br>

## Assertions

- `context.assertion_failure_proc` was **removed**, replaced by `runtime.assertion_failure_proc`.
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

<br>

## Logger

- `context.logger` was **removed**, replaced by `log.default_logger`.
- The logger provides a system where the API provides the entry points so that user-defined logging implementations can print the messages in the terminal.
- The idea is ok, but I don't think it's that practical.

#### Problems I've encountered
- The API can choose to override the `context.logger` and use whatever it sees fit. It is not enforced that a library shouldn't touch the user-defined configurations.
- Not every api uses log. This is not enforced. A lot of APIs just print with `fmt`.
- A lot of APIs don't actually print anything.
- There's no room for easy coloring of the things in the terminal. There's a fixed template following the predefined `Options` in the library. One could wrap the log procedures or create their own logging procedure, but trying to print something colorful and customizable is not ergonomic at all with the `log` API.
- I have never seen a third-party Odin API that uses the logger to its full extent.
- In the end, the library just seems limiting and extremely situational.
- It doesn't seem practical, even tho I can appreciate the idea.
- If the point of `context` is to improve interoperability with bad APIs, using `context.logger` consistently and correctly seems like the last thing they would do.
- To be fair, the ONLY reasons I have ever used logger were: prints `#caller_location`, and makes error red, warns yellow. It was never for logging flexibility between the user and the API. There is no clear intuition for this.
- The library itself is ok, but I don't think something so situational, misused, or impractical should be part of the **runtime**. Just like `core:fmt`, this should only be `core`.
- The `context` usage for it seems really hard to justify.
- Is there a way the logger could be built that would make it reliable and a standard for any API that wants to use it? I'm not sure, I just don't think the current implementation solves that.
- My changes don't remove `core:log`, just make logger decoupled from the `runtime` and `context`.


<br>

## Random Generator

- `context.random_generator` was removed, replaced by `runtime.global_random_generator`.
- Same argument as previously removed patterns from `context`.
- A `Random_Generator` is no longer used implicitly in any library.


