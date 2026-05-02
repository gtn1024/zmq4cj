## 新增需求

### 需求：sendMultipart 方法
系统应当提供 `sendMultipart(frames: Array<Array<UInt8>>): Unit` 方法，发送多帧消息。

#### 场景：发送两帧消息
- **当** 调用 `socket.sendMultipart([header, payload])` 时
- **则** 第一帧以 `ZMQ_SNDMORE` flag 发送，第二帧以 `flags=0` 发送

#### 场景：发送三帧消息
- **当** 调用 `socket.sendMultipart([frame1, frame2, frame3])` 时
- **则** 前两帧以 `ZMQ_SNDMORE` flag 发送，最后一帧以 `flags=0` 发送

#### 场景：发送单帧消息
- **当** 调用 `socket.sendMultipart([data])` 时
- **则** 唯一的一帧以 `flags=0` 发送，行为等同于 `send(data)`

#### 场景：发送空帧列表抛出异常
- **当** 调用 `socket.sendMultipart([])` 时
- **则** 抛出 `ZmqError` 或 IllegalArgumentException

#### 场景：发送包含空帧的消息
- **当** 调用 `socket.sendMultipart([header, []])` 时（payload 为空数组）
- **则** 成功发送两帧，第二帧长度为 0

#### 场景：发送中间帧失败时不发送后续帧
- **当** `sendMultipart` 发送第 N 帧时 `zmq_msg_send` 返回 -1
- **则** 抛出 `ZmqError`，不继续发送剩余帧

### 需求：recvMultipart 方法
系统应当提供 `recvMultipart(): Array<Array<UInt8>>` 方法，接收多帧消息的所有帧。

#### 场景：接收两帧消息
- **当** 对端发送 `[header, payload]` 两帧消息时
- **则** `recvMultipart()` 返回包含两个 `Array<UInt8>` 的数组，内容分别对应 header 和 payload

#### 场景：接收单帧消息
- **当** 对端发送单帧消息时
- **则** `recvMultipart()` 返回包含一个元素的数组

#### 场景：接收多帧消息保持帧顺序
- **当** 对端发送 `[frame1, frame2, frame3]` 时
- **则** 返回数组的元素顺序为 `[frame1, frame2, frame3]`

#### 场景：接收保持每帧内容完整
- **当** 对端发送 `["header".toArray(), "payload".toArray()]` 时
- **则** `recvMultipart()` 返回 `["header".toArray(), "payload".toArray()]`，每帧内容独立完整
