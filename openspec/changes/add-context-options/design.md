## Context

ZmqContext wraps `zmq_ctx_new`/`zmq_ctx_term` with no configuration options. The FFI declarations for `zmq_ctx_set` and `zmq_ctx_get` already exist in `zmq_ffi.cj` but are unused. libzmq supports 9 context options (IO_THREADS, MAX_SOCKETS, etc.) that control context behavior.

## Goals / Non-Goals

**Goals:**
- Expose all 9 context options via a `ContextOption` enum
- Add `set(option: ContextOption, value: Int32)` and `get(option: ContextOption): Int32` to ZmqContext
- Follow the same patterns as `SocketOption` (enum + typed accessors)
- Validate context is not closed before operations

**Non-Goals:**
- Named convenience methods per option (e.g., `setIoThreads()`) — keep it simple with generic set/get
- `zmq_ctx_set_ext`/`zmq_ctx_get_ext` (binary context options, not commonly needed)
- `zmq_ctx_shutdown` (separate concern, out of scope)

## Decisions

1. **Int32-only API**: All context options use `Int32` values in libzmq (unlike socket options which have Int64/UInt64/binary variants). A single `set(option, value: Int32)` / `get(option): Int32` pair is sufficient.

2. **ContextOption enum in zmq_types.cj**: Follows the same pattern as `SocketOption` — all enums in one file.

3. **Set must be called before socket creation**: libzmq requires context options to be set before `zmq_socket()` is called. We document this but don't enforce it — let libzmq return the error naturally.

4. **Thread safety**: Context set/get operations are protected by the existing `mutex` in ZmqContext, consistent with `socket()` and `close()`.

## Risks / Trade-offs

- [Some options like SOCKET_LIMIT are read-only] → Document in enum comments; libzmq returns ETERM for write attempts
- [Setting options after socket creation may silently fail] → Document usage pattern; don't add enforcement logic
