## 新增需求

### 需求：ZmqSocket 类实现 Resource 接口
系统应当提供 `ZmqSocket` 类，实现 `Resource` 接口，包含 `isClosed(): Bool` 和 `close(): Unit` 方法。

#### 场景：ZmqSocket 支持 try-with-resources
- **当** 使用 `try (socket = ctx.socket(SocketType.REQ)) { ... }` 时
- **则** 离开代码块时自动调用 `close()`，内部调用 `zmq_close()`

#### 场景：ZmqSocket 的 close 操作是幂等的
- **当** 对已关闭的 ZmqSocket 调用 `close()` 时
- **则** 不执行任何操作（不会重复释放）

### 需求：ZmqSocket bind 操作
系统应当提供 `bind(addr: String): Unit` 方法。

#### 场景：绑定到 TCP 地址
- **当** 调用 `socket.bind("tcp://*:5555")` 时
- **则** 使用该地址调用 `zmq_bind`，成功时不抛出异常

#### 场景：bind 失败抛出 ZmqError
- **当** `zmq_bind` 返回 -1（如地址已被占用）时
- **则** 抛出 `ZmqError` 异常，包含 errno 和错误描述

### 需求：ZmqSocket connect 操作
系统应当提供 `connect(addr: String): Unit` 方法。

#### 场景：连接到 TCP 地址
- **当** 调用 `socket.connect("tcp://localhost:5555")` 时
- **则** 使用该地址调用 `zmq_connect`，成功时不抛出异常

#### 场景：connect 失败抛出 ZmqError
- **当** `zmq_connect` 返回 -1 时
- **则** 抛出 `ZmqError` 异常，包含 errno 和错误描述

### 需求：ZmqSocket send 操作
系统应当提供 `send(data: Array<UInt8>): Unit` 方法。

#### 场景：发送二进制数据
- **当** 调用 `socket.send([72, 101, 108, 108, 111])` 时
- **则** 通过 `zmq_send` 发送数据，成功时不抛出异常

#### 场景：send 失败抛出 ZmqError
- **当** `zmq_send` 返回 -1 时
- **则** 抛出 `ZmqError` 异常，包含 errno 和错误描述

### 需求：ZmqSocket recv 操作
系统应当提供 `recv(): Array<UInt8>` 方法。

#### 场景：接收二进制数据
- **当** 有消息可用且调用 `socket.recv()` 时
- **则** 返回接收到的字节作为 `Array<UInt8>`

#### 场景：接收保持消息内容完整
- **当** 向 Socket 发送 "Hello" 后调用 `recv()` 时
- **则** 返回的数组等于 `[72, 101, 108, 108, 111]`

#### 场景：接收分配正确的缓冲区大小
- **当** 调用 `recv()` 时
- **则** 在拷贝数据前分配 `zmq_msg_size()` 字节的缓冲区

### 需求：ZmqSocket 订阅设置
系统应当为 SUB Socket 提供 `setSubscribe(topic: String): Unit` 方法。

#### 场景：订阅所有消息
- **当** 在 SUB Socket 上调用 `socket.setSubscribe("")` 时
- **则** 使用 ZMQ_SUBSCRIBE 和空主题调用 `zmq_setsockopt`

#### 场景：订阅特定主题
- **当** 在 SUB Socket 上调用 `socket.setSubscribe("weather.")` 时
- **则** 使用 ZMQ_SUBSCRIBE 和主题 "weather." 调用 `zmq_setsockopt`

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

## Thread-Safety Requirements (from thread-safety change)

### 需求：ZmqSocket 类实现 Resource 接口
系统应当提供 `ZmqSocket` 类，实现 `Resource` 接口，包含 `isClosed(): Bool` 和 `close(): Unit` 方法。`close()` SHALL 使用 `AtomicBool.compareAndSwap` 确保底层 `zmq_close` 只被调用一次。

#### 场景：ZmqSocket 支持 try-with-resources
- **WHEN** 使用 `try (socket = ctx.socket(SocketType.REQ)) { ... }` 时
- **THEN** 离开代码块时自动调用 `close()`，内部调用 `zmq_close()`

#### 场景：ZmqSocket 的 close 操作是幂等的
- **WHEN** 对已关闭的 ZmqSocket 调用 `close()` 时
- **THEN** `compareAndSwap` 返回 `false`，不执行任何操作（不会重复释放）

#### 场景：多线程并发调用 close 只执行一次
- **WHEN** 多个线程同时调用同一 ZmqSocket 的 `close()` 时
- **THEN** 只有一个线程的 `compareAndSwap(false, true)` 成功，只有该线程调用 `zmq_close`，其他线程直接返回
