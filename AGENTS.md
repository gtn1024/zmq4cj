# AGENTS.md

## Project Overview

zmq is a ZeroMQ (libzmq) binding library for the Cangjie (仓颉) programming language. It wraps the C library via FFI (`foreign func`) and provides a safe, idiomatic Cangjie API.

## Tech Stack

- **Language:** Cangjie (仓颉) v1.1.0
- **Package Manager:** cjpm
- **Build System:** `build.cj` pre-build hook compiles libzmq from source via cmake + make
- **FFI:** `foreign func` declarations bind libzmq C functions
- **C Library:** libzmq v4.3.5 (git submodule at `vendor/libzmq/`)

## Build & Test Commands

```bash
cjpm build                                    # Compile (auto-builds libzmq on first run)
cjpm test                                     # Run unit tests
cd benchmark && cjpm run                      # Run benchmarks (~5 min)
```

## Project Structure

```
src/
├── zmq_ffi.cj        # FFI declarations (foreign func) — unsafe layer
├── zmq_types.cj      # SocketType, SocketOption, SendRecvFlags, PollEvent enums
├── zmq_error.cj      # ZmqError exception class, checkResult helper
├── zmq_context.cj    # ZmqContext class (Resource interface)
├── zmq_socket.cj     # ZmqSocket class (Resource interface)
├── zmq_poll.cj       # PollItem class, ZmqPoll static class (zmq_poll wrapper)
├── zmq_proxy_class.cj # ZmqProxy static class (zmq_proxy/zmq_proxy_steerable wrapper)
├── zmq_common.cj     # Internal String↔CString conversion utilities
└── zmq_test.cj       # Unit tests
build.cj              # Pre-build script: compiles libzmq.a from source
cjpm.toml             # Package config with [ffi.c] per target platform
benchmark/            # Standalone benchmark project (cjpm run)
vendor/libzmq/        # git submodule (libzmq source)
```

## Architecture

Three-layer design:
1. **FFI layer** (`zmq_ffi.cj`): Raw `foreign func` declarations, 1:1 mapping to C API. All calls require `unsafe` blocks.
2. **Internal layer** (`zmq_common.cj`, `zmq_error.cj`): CString conversion, error checking via `checkResult(rc)`.
3. **Public API** (`zmq_context.cj`, `zmq_socket.cj`, `zmq_poll.cj`, `zmq_proxy_class.cj`, `zmq_types.cj`): Safe API using `Resource` interface, exceptions instead of error codes. No `unsafe`/`CPointer`/`CString` exposed to users.

## Cangjie Gotchas

- **No `pointee` on CPointer** — use `CPointer<T>.read()` and `CPointer<T>.write(val)` instead
- **No `&` address-of operator** — use `CPointer<T>(inout var)` to get a pointer to a stack variable
- **`inout` only works on `var` locals** — cannot take address of array element, struct field in expression, or `let` variable
- **Array has no literal constructor** — `Array<Foo>([a, b])` does not compile. Use `ArrayList<Foo>()` + `.add()` + `.toArray()`
- **CPointer type cast** — `CPointer<T>(CPointer<Unit>(ptr))` for reinterpret cast, NOT `ptr.asCPointer<T>()`
- **`@C struct` fields** — must be `var` with explicit initializer (e.g., `var _0: UInt8 = 0`)
- **`CString` ≠ `CPointer<UInt8>`** — use `cs.getChars()` to get `CPointer<UInt8>` from a `CString`
- **`acquireArrayRawData<T>` / `releaseArrayRawData<T>`** — public API in `std.core` for getting raw pointer to Array's memory. No malloc/free between acquire and release (GC deadlock risk).
- Cangjie enums are ADTs; integer values exposed via `.value` property
- Tests use `@Test` / `@TestCase` / `@Assert` from `std.unittest`

## Type Mapping (C ↔ Cangjie)

| C Type | Cangjie Type |
|--------|-------------|
| `void*` | `CPointer<Unit>` |
| `size_t` | `UIntNative` |
| `int` | `Int32` |
| `short` | `Int16` |
| `const char*` | `CString` |

## Key Conventions

- All FFI calls are wrapped in `unsafe` blocks, never exposed in public API
- All errors throw `ZmqError` — no return-code checking by users
- `ZmqContext` and `ZmqSocket` implement `Resource` for `try-with-resources` auto-cleanup
- `close()` is idempotent — uses `AtomicBool.compareAndSwap` to ensure underlying C cleanup runs exactly once
- `ZmqSocket` operations (`send`/`recv`/`bind`/`connect`) are NOT thread-safe — one socket per thread
- libzmq is a C++ library; Linux needs `-lstdc++ -lgcc_s`, macOS needs `-lc++` in link options
- **Windows not supported** — ABI mismatch between system MinGW (libstdc++) and Cangjie's bundled libc++

## Performance Notes

- `send()` uses `zmq_send` (1 FFI call) + `acquireArrayRawData` (zero-copy from Array)
- `recv()` uses `zmq_msg_recv` with stack-allocated `ZmqMsg` (`inout` pointer, no malloc)
- `copyCPointerToArray` uses `memcpy` via `acquireArrayRawData`
- Benchmark: ~1.4M msg/s inproc 64B, ~2.3M msg/s tcp 64B on ARM64 Linux

## CI

- Platforms: Linux (x86_64) + macOS (x86_64 + ARM64)
- Windows disabled due to ABI issues
- Tests use unique TCP ports per test case to avoid conflicts

## Workflow

- **Do not auto-commit** — only commit when user explicitly says "commit"
- **Do not auto-push** — only push when user explicitly says "push"
- Use OpenSpec (`openspec`) for change management: propose → apply → verify → archive
