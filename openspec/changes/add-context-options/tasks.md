## 1. Types

- [x] 1.1 Add `ContextOption` enum to `src/zmq_types.cj` with 8 members (IO_THREADS=1 through THREAD_NAME_PREFIX=9), each with Int32 value

## 2. Context API

- [x] 2.1 Add `set(option: ContextOption, value: Int32)` to ZmqContext — wraps `zmq_ctx_set` with closed check, synchronized on mutex
- [x] 2.2 Add `get(option: ContextOption): Int32` to ZmqContext — wraps `zmq_ctx_get` with closed check, synchronized on mutex

## 3. Tests

- [x] 3.1 Test set and get IO_THREADS round-trip
- [x] 3.2 Test get SOCKET_LIMIT returns positive value (read-only option)
- [x] 3.3 Test set/get on closed context throws ZmqError
- [x] 3.4 Test set MAX_SOCKETS and verify with get
