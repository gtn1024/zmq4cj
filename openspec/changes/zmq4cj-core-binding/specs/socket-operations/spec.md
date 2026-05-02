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
