## 为什么

ZeroMQ 多帧消息（multipart message）是构建高级通信模式的基础能力。DEALER/ROUTER、PUB/SUB with envelopes、代理（proxy）等场景都依赖多帧消息。当前 zmq4cj 仅支持单帧收发，无法处理用户已有的基于 `recv_multipart` 的 PULL 消费端（如 Python 中 `frames = s.recv_multipart()` 拆分 header + payload 的模式）。

## 变更内容

- 为 `ZmqSocket` 新增 `sendMultipart(frames)` / `recvMultipart()` 便捷方法
- 为现有 `send` / `recv` 增加 flags 参数支持（`SendRecvFlags`：DONTWAIT、SNDMORE）
- 新增 `hasReceiveMore()` 方法（查询 `ZMQ_RCVMORE` socket 选项）
- 新增 `zmq_msg_send` FFI 声明
- 在 `SocketOption` 枚举中添加 `RCVMORE`
- 参照 pyzmq 和 jeromq 的分层设计：底层 flags + RCVMORE 支持，上层组合出 multipart 便捷 API

## 能力

### 新增能力

- `multipart-messaging`：多帧消息收发（sendMultipart / recvMultipart + hasReceiveMore）

### 修改能力

- `ffi-bindings`：新增 `zmq_msg_send` FFI 声明
- `socket-operations`：现有 send/recv 增加 flags 重载，新增 multipart 方法

## 影响

- **API 兼容性**：现有 `send(data)` / `recv()` 签名不变，新增重载方法
- **SocketOption 枚举**：新增 `RCVMORE` 成员
- **zmq_ffi.cj**：新增一行 `zmq_msg_send` 声明
