## MODIFIED Requirements

### Requirement: send 方法使用 zmq_send 实现

`ZmqSocket.send(data: Array<UInt8>, flags: Int32)` 内部使用 `zmq_send` API 而非 `zmq_msg_send`。

#### Scenario: 发送普通消息
- **WHEN** 调用 `send(data, flags)` 且 data 非空
- **THEN** 通过 `acquireArrayRawData` 获取底层数据指针，调用 `zmq_send(socket, pointer, size, flags)`，然后 `releaseArrayRawData`
- **THEN** 行为与原 zmq_msg_send 实现完全一致（接收方收到的数据相同）

#### Scenario: 发送空消息
- **WHEN** 调用 `send(data, flags)` 且 data.size == 0
- **THEN** 调用 `zmq_send(socket, CPointer<Unit>(), 0, flags)`
- **THEN** 接收方收到长度为 0 的消息

#### Scenario: 发送失败抛异常
- **WHEN** zmq_send 返回 -1
- **THEN** 抛出 ZmqError，包含 zmq_errno() 返回的错误码

#### Scenario: multipart 发送自动受益
- **WHEN** 调用 `sendMultipart(frames)`
- **THEN** 内部循环调用优化后的 send，行为不变
