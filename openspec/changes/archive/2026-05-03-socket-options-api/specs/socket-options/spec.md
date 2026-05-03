## ADDED Requirements

### Requirement: setIntOption 方法

`ZmqSocket` 应当提供 `setIntOption(option: SocketOption, value: Int32): Unit` 方法，用于设置整数类型的 socket 选项。

#### Scenario: 设置 LINGER 选项
- **WHEN** 调用 `socket.setIntOption(SocketOption.LINGER, 0)`
- **THEN** 调用 `zmq_setsockopt` 设置 ZMQ_LINGER 为 0
- **THEN** 关闭 socket 时不等待未发送的消息

#### Scenario: 设置超时选项
- **WHEN** 调用 `socket.setIntOption(SocketOption.RCVTIMEO, 5000)`
- **THEN** recv 操作在 5 秒后超时，抛出 ZmqError（EAGAIN）

#### Scenario: 设置失败抛出异常
- **WHEN** zmq_setsockopt 返回 -1
- **THEN** 抛出 ZmqError

### Requirement: getIntOption 方法

`ZmqSocket` 应当提供 `getIntOption(option: SocketOption): Int32` 方法，用于读取整数类型的 socket 选项。

#### Scenario: 读取 LINGER 值
- **WHEN** 先调用 `setIntOption(SocketOption.LINGER, 100)`，再调用 `getIntOption(SocketOption.LINGER)`
- **THEN** 返回 100

#### Scenario: 读取 RCVMORE
- **WHEN** 接收到多帧消息的非最后一帧后调用 `getIntOption(SocketOption.RCVMORE)`
- **THEN** 返回 1

### Requirement: setStringOption 方法

`ZmqSocket` 应当提供 `setStringOption(option: SocketOption, value: String): Unit` 方法，用于设置字符串类型的 socket 选项。

#### Scenario: SUBSCRIBE 订阅
- **WHEN** 调用 `socket.setStringOption(SocketOption.SUBSCRIBE, "topic")`
- **THEN** 行为与 `socket.setSubscribe("topic")` 一致

#### Scenario: UNSUBSCRIBE 取消订阅
- **WHEN** 调用 `socket.setStringOption(SocketOption.UNSUBSCRIBE, "topic")`
- **THEN** 取消该主题的订阅

## MODIFIED Requirements

### Requirement: setSubscribe 内部复用 setStringOption

`setSubscribe` 方法内部改为调用 `setStringOption(SocketOption.SUBSCRIBE, topic)`，对外行为不变。

#### Scenario: setSubscribe 行为不变
- **WHEN** 调用 `socket.setSubscribe("weather.")`
- **THEN** 行为与修改前完全一致
