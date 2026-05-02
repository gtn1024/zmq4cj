## 修改需求

### 需求：send 方法迁移到 zmq_msg_send
系统应当将 `send(data: Array<UInt8>)` 的内部实现从 `zmq_send` 迁移到 `zmq_msg_init_size` + `zmq_msg_send` + `zmq_msg_close`，保持外部签名不变。

#### 场景：send 使用 zmq_msg_t API 发送数据
- **当** 调用 `socket.send("Hello".toArray())` 时
- **则** 内部通过 `zmq_msg_init_size` 分配消息、拷贝数据、`zmq_msg_send` 发送、`zmq_msg_close` 释放

#### 场景：send 迁移后行为与之前一致
- **当** 使用迁移后的 `send` 发送数据时
- **则** 接收端 `recv` 收到的数据与迁移前完全一致

#### 场景：send 失败时抛出 ZmqError
- **当** `zmq_msg_send` 返回 -1 时
- **则** 先 `zmq_msg_close` 释放消息，再抛出 `ZmqError`

### 需求：send 带 flags 参数重载
系统应当提供 `send(data: Array<UInt8>, flags: Int32): Unit` 重载方法。

#### 场景：使用 SNDMORE flag 发送中间帧
- **当** 调用 `socket.send(data, SendRecvFlags.SNDMORE.value)` 时
- **则** 消息以 `ZMQ_SNDMORE` flag 发送，接收端可通过 RCVMORE 检测到后续帧

#### 场景：使用 flags=0 等同于无参 send
- **当** 调用 `socket.send(data, 0)` 时
- **则** 行为与 `socket.send(data)` 完全一致

### 需求：recv 带 flags 参数重载
系统应当提供 `recv(flags: Int32): Array<UInt8>` 重载方法。

#### 场景：使用 DONTWAIT flag 非阻塞接收
- **当** 调用 `socket.recv(SendRecvFlags.DONTWAIT.value)` 且无消息时
- **则** 抛出 `ZmqError`（errno=EAGAIN）

#### 场景：使用 flags=0 等同于无参 recv
- **当** 调用 `socket.recv(0)` 时
- **则** 行为与 `socket.recv()` 完全一致

### 需求：hasReceiveMore 方法
系统应当提供 `hasReceiveMore(): Bool` 方法，查询 `ZMQ_RCVMORE` socket 选项。

#### 场景：收到多帧消息的中间帧后 hasReceiveMore 返回 true
- **当** 接收到多帧消息的非最后一帧时
- **则** `hasReceiveMore()` 返回 `true`

#### 场景：收到多帧消息的最后一帧后 hasReceiveMore 返回 false
- **当** 接收到多帧消息的最后一帧时
- **则** `hasReceiveMore()` 返回 `false`

#### 场景：收到单帧消息后 hasReceiveMore 返回 false
- **当** 接收到单帧消息后
- **则** `hasReceiveMore()` 返回 `false`

### 需求：SocketOption 枚举新增 RCVMORE
`SocketOption` 枚举应当新增 `RCVMORE` 成员，值为 13。

#### 场景：RCVMORE 值与 ZMQ_RCVMORE 常量一致
- **当** 访问 `SocketOption.RCVMORE.value` 时
- **则** 返回 `13`
