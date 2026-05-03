## Why

当前 `send()` 使用 `zmq_msg_init_size` → `zmq_msg_data` → memcpy → `zmq_msg_send` → `zmq_msg_close` 共 5 次 FFI 调用。libzmq 提供了更简单的 `zmq_send(socket, buf, len, flags)` API，只需 1 次 FFI 调用即可完成发送。结合 `acquireArrayRawData` 获取 Array 底层指针后直接传给 `zmq_send`，可以显著减少 FFI 调用开销，提升小消息吞吐量。

## What Changes

- 重写 `ZmqSocket.send(data, flags)`：使用 `zmq_send` 替代 `zmq_msg_send`，消除 ZmqMsg 栈分配和 5 次 FFI 调用
- 重写 `ZmqSocket.send(data)` 无参版本保持不变（委托到上面）
- `zmq_ffi.cj` 中的 `zmq_send` 声明已存在，无需新增

## Capabilities

### New Capabilities

（无新能力）

### Modified Capabilities

- `socket-operations`：send 方法内部实现从 zmq_msg API 切换到 zmq_send API，公共签名不变

## Impact

- `src/zmq_socket.cj`：send 方法实现
- `src/zmq_ffi.cj`： zmq_send 已声明，无需改动
- 公共 API 不变，无破坏性变更
