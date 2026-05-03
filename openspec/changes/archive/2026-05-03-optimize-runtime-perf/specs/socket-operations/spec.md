## MODIFIED Requirements

### Requirement: ZmqSocket send 操作
系统应当提供 `send(data: Array<UInt8>, flags: Int32): Unit` 方法，使用栈分配的 `ZmqMsg` 和 `memcpy` 进行数据拷贝，不使用堆分配。

#### 场景：发送二进制数据
- **当** 调用 `socket.send([72, 101, 108, 108, 111], 0)` 时
- **则** 通过 `zmq_msg_send` 发送数据，成功时不抛出异常

#### 场景：send 使用栈分配的 ZmqMsg
- **当** 调用 `send` 时
- **则** `ZmqMsg` 结构体在栈上分配，不调用 `LibC.malloc` 或 `LibC.free`

#### 场景：send 使用 memcpy 拷贝数据
- **当** 调用 `send` 时
- **则** 数据通过 `memcpy` 从 `Array<UInt8>` 批量拷贝到 `zmq_msg_data()` 返回的指针

#### 场景：send 失败时抛出 ZmqError
- **当** `zmq_msg_send` 返回 -1 时
- **则** 先 `zmq_msg_close` 释放消息，再抛出 `ZmqError`

### Requirement: ZmqSocket recv 操作
系统应当提供 `recv(flags: Int32): Array<UInt8>` 方法，使用栈分配的 `ZmqMsg` 和 `memcpy` 进行数据拷贝，不使用堆分配。

#### 场景：接收二进制数据
- **当** 有消息可用且调用 `socket.recv(0)` 时
- **则** 返回接收到的字节作为 `Array<UInt8>`

#### 场景：recv 使用栈分配的 ZmqMsg
- **当** 调用 `recv` 时
- **则** `ZmqMsg` 结构体在栈上分配，不调用 `LibC.malloc` 或 `LibC.free`

#### 场景：recv 使用 memcpy 拷贝数据
- **当** 调用 `recv` 时
- **则** 数据通过 `memcpy` 从 `zmq_msg_data()` 返回的指针批量拷贝到 `Array<UInt8>`

#### 场景：接收保持消息内容完整
- **当** 向 Socket 发送 "Hello" 后调用 `recv()` 时
- **则** 返回的数组等于 `[72, 101, 108, 108, 111]`

### Requirement: hasReceiveMore 方法
系统应当提供 `hasReceiveMore(): Bool` 方法，使用栈变量查询 `ZMQ_RCVMORE` socket 选项，不使用堆分配。

#### 场景：收到多帧消息的中间帧后 hasReceiveMore 返回 true
- **当** 接收到多帧消息的非最后一帧时
- **则** `hasReceiveMore()` 返回 `true`

#### 场景：收到多帧消息的最后一帧后 hasReceiveMore 返回 false
- **当** 接收到多帧消息的最后一帧时
- **则** `hasReceiveMore()` 返回 `false`

#### 场景：hasReceiveMore 不使用堆分配
- **当** 调用 `hasReceiveMore()` 时
- **则** 使用栈上的 `Int32` 和 `UIntNative` 变量，不调用 `LibC.malloc` 或 `LibC.free`
