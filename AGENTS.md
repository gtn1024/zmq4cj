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
- libzmq is a C++ library; Linux needs `-lstdc++ -lgcc_s`, macOS needs `-lc++`, Windows needs `-lc++ -lunwind -lws2_32 -liphlpapi` in link options
- **Windows** supported natively: zig builds libzmq for `x86_64-windows-gnu` producing a libc++ ABI that matches Cangjie's llvm-mingw runtime (system MinGW g++ would produce libstdc++ and fail to link — the historical Windows CI failure). The whole Windows build is inlined in `build.cj` (no separate script). The same flow also works as a cross-build from Linux/macOS for local dev

## Performance Notes

- `send()` uses `zmq_send` (1 FFI call) + `acquireArrayRawData` (zero-copy from Array)
- `recv()` uses `zmq_msg_recv` with stack-allocated `ZmqMsg` (`inout` pointer, no malloc)
- `copyCPointerToArray` uses `memcpy` via `acquireArrayRawData`
- Benchmark: ~1.4M msg/s inproc 64B, ~2.3M msg/s tcp 64B on ARM64 Linux

## CI

- Platforms: Linux (x86_64) + macOS (x86_64 + ARM64) + Windows (x86_64)
- `windows` job: runs natively on `windows-latest`; zig builds libzmq (libc++ ABI), then `cjpm build` + `cjpm test` run natively (tests execute for real, unlike a cross-build)
- Tests use unique TCP ports per test case to avoid conflicts

## Windows build (build.cj + zig)

- The Windows branch is selected by `@When[target == "x86_64-w64-mingw32"]` (cjpm compiles `build.cj` with `--cfg=target=...`). Everything is inline in `stageWindowsBuild()` — no shell script. Works for native Windows builds (`cjpm build` on Windows) and cross-builds (`cjpm build --target x86_64-w64-mingw32` on Linux/macOS)
- `ZIG` env var must point at a zig binary
- build.cj generates (via `std.fs`) tiny platform-aware launcher scripts (`.sh` on Unix / `.bat` on Windows) for `CMAKE_C/CXX_COMPILER` (zig needs a `cc`/`c++` subcommand) and a windres shim (zig has no windres; version.rc resources are meaningless in a static `.a` — the shim copies a prebuilt empty COFF object). Plus an iphlpapi stub (Cangjie's bundled mingw is minimal)
- `CMAKE_AR=llvm-ar` + `CMAKE_RANLIB=no-op`: cmake emits an `ld.lld`-compatible archive directly. GNU `ar`/`ranlib` archives are mis-read by `ld.lld` (all symbols come out undefined), so `ranlib` must NOT run after `llvm-ar`
- cmake workarounds: `-DZMQ_WIN32_WINNT=0x0A00` (avoid empty `_WIN32_WINNT` when cross-compiling), `-DZMQ_HAVE_IPC=OFF` (no `sys/socket.h` on mingw), `-O2 -fno-sanitize=undefined` in the zig launchers (avoid UBSan refs)
- **Native vs cross**: on a native Windows build (host == Windows) ffi.c resolves directly to `vendor/build/windows/lib`. On a cross-build, cjpm resolves ffi.c via the HOST target's path (`vendor/build/<host>/lib`), so `build.cj` mirrors the PE `libzmq_vendor.a` into the host lib dir and drops a `.cross-mirror` marker so a later native build detects the foreign-format artifact and rebuilds (ELF/Mach-O) instead of linking a PE lib natively

## Workflow

- **Do not auto-commit** — only commit when user explicitly says "commit"
- **Do not auto-push** — only push when user explicitly says "push"
- Use OpenSpec (`openspec`) for change management: propose → apply → verify → archive
