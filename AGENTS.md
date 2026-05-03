# AGENTS.md

## Project Overview

zmq4cj is a ZeroMQ (libzmq) binding library for the Cangjie (仓颉) programming language. It wraps the C library via FFI (`foreign func`) and provides a safe, idiomatic Cangjie API.

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
```

## Project Structure

```
src/
├── zmq_ffi.cj        # FFI declarations (foreign func) — unsafe layer
├── zmq_types.cj      # SocketType, SocketOption, SendRecvFlags enums
├── zmq_error.cj      # ZmqError exception class, checkResult helper
├── zmq_context.cj    # ZmqContext class (Resource interface)
├── zmq_socket.cj     # ZmqSocket class (Resource interface)
├── zmq_common.cj     # Internal String↔CString, Array↔CPointer utilities
└── zmq_test.cj       # Unit tests (REQ/REP, PUB/SUB, PUSH/PULL)
build.cj              # Pre-build script: compiles libzmq.a from source
cjpm.toml             # Package config with [ffi.c] per target platform
vendor/libzmq/        # git submodule (libzmq source)
```

## Architecture

Three-layer design:
1. **FFI layer** (`zmq_ffi.cj`): Raw `foreign func` declarations, 1:1 mapping to C API. All calls require `unsafe` blocks.
2. **Internal layer** (`zmq_common.cj`, `zmq_error.cj`): CString conversion, error checking via `checkResult(rc)`.
3. **Public API** (`zmq_context.cj`, `zmq_socket.cj`, `zmq_types.cj`): Safe API using `Resource` interface, exceptions instead of error codes. No `unsafe`/`CPointer`/`CString` exposed to users.

## Cangjie Syntax Notes

- Cangjie enums are ADTs (not C-style integer enums); integer values are exposed via `.value` property
- `super()` must be the first expression in a constructor
- `LibC.malloc<T>(count: Int64)` for heap allocation; `LibC.free()` to release
- `CPointer<T>.isNull()` for null checks; `CPointer<Unit>()` creates null pointer
- `CString.toString()` converts to `String`; `LibC.mallocCString(s)` converts `String` to `CString`
- Properties use `prop` with explicit `get()` / `set()` blocks
- `@When[os == "Linux"]` for conditional compilation
- `spawn { => ... }` creates threads; `Future<T>.get()` waits for result
- Tests use `@Test` / `@TestCase` / `@Assert` from `std.unittest`

## Type Mapping (C ↔ Cangjie)

| C Type | Cangjie Type |
|--------|-------------|
| `void*` | `CPointer<Unit>` |
| `size_t` | `UIntNative` |
| `int` | `Int32` |
| `const char*` | `CString` |
| `char*` (output) | `CPointer<UInt8>` |

## Key Conventions

- All FFI calls are wrapped in `unsafe` blocks, never exposed in public API
- All errors throw `ZmqError` (extends `Exception`) — no return-code checking by users
- `ZmqContext` and `ZmqSocket` implement `Resource` for `try-with-resources` auto-cleanup
- `close()` is idempotent — uses `AtomicBool.compareAndSwap` to ensure the underlying C cleanup runs exactly once
- `ZmqContext.close()` and `socket()` are additionally protected by `Mutex` + `synchronized` for thread safety
- `ZmqSocket` operations (`send`/`recv`/`bind`/`connect`) are NOT thread-safe — one socket per thread
- libzmq is a C++ library; Linux targets need `-lstdc++ -lgcc_s` in link options
