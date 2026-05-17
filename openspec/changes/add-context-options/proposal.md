## Why

ZmqContext currently only supports creating contexts and sockets with default settings. Users cannot configure IO thread count, max socket limit, thread priority, or other context-level parameters that `zmq_ctx_set`/`zmq_ctx_get` provide. These are essential for tuning performance in production workloads.

## What Changes

- Add `ContextOption` enum with all libzmq context options (IO_THREADS, MAX_SOCKETS, SOCKET_LIMIT, THREAD_PRIORITY, THREAD_SCHED_POLICY, MAX_MSGSZ, MSG_T_SIZE, THREAD_NAME_PREFIX)
- Add `set(option, value)` and `get(option)` methods to `ZmqContext`
- FFI declarations for `zmq_ctx_set`/`zmq_ctx_get` already exist in `zmq_ffi.cj`

## Capabilities

### New Capabilities

- `context-options`: Context-level configuration via `zmq_ctx_set`/`zmq_ctx_get` — typed getters/setters on ZmqContext

### Modified Capabilities

- `context-management`: Extends ZmqContext API with set/get option methods

## Impact

- `src/zmq_types.cj` — new `ContextOption` enum
- `src/zmq_context.cj` — add `set()`/`get()` methods
- `src/zmq_test.cj` — new tests for context options
