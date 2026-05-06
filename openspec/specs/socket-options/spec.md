## 新增需求

### 需求：setIntOption 方法

`ZmqSocket` 应当提供 `setIntOption(option: SocketOption, value: Int32): Unit` 方法，用于设置整数类型的 socket 选项。

#### 场景：设置 LINGER 选项
- **WHEN** 调用 `socket.setIntOption(SocketOption.LINGER, 0)`
- **THEN** 调用 `zmq_setsockopt` 设置 ZMQ_LINGER 为 0
- **THEN** 关闭 socket 时不等待未发送的消息

#### 场景：设置超时选项
- **WHEN** 调用 `socket.setIntOption(SocketOption.RCVTIMEO, 5000)`
- **THEN** recv 操作在 5 秒后超时，抛出 ZmqError（EAGAIN）

#### 场景：设置失败抛出异常
- **WHEN** zmq_setsockopt 返回 -1
- **THEN** 抛出 ZmqError

### 需求：getIntOption 方法

`ZmqSocket` 应当提供 `getIntOption(option: SocketOption): Int32` 方法，用于读取整数类型的 socket 选项。

#### 场景：读取 LINGER 值
- **WHEN** 先调用 `setIntOption(SocketOption.LINGER, 100)`，再调用 `getIntOption(SocketOption.LINGER)`
- **THEN** 返回 100

#### 场景：读取 RCVMORE
- **WHEN** 接收到多帧消息的非最后一帧后调用 `getIntOption(SocketOption.RCVMORE)`
- **THEN** 返回 1

### 需求：setStringOption 方法

`ZmqSocket` 应当提供 `setStringOption(option: SocketOption, value: String): Unit` 方法，用于设置字符串类型的 socket 选项。

#### 场景：SUBSCRIBE 订阅
- **WHEN** 调用 `socket.setStringOption(SocketOption.SUBSCRIBE, "topic")`
- **THEN** 行为与 `socket.setSubscribe("topic")` 一致

#### 场景：UNSUBSCRIBE 取消订阅
- **WHEN** 调用 `socket.setStringOption(SocketOption.UNSUBSCRIBE, "topic")`
- **THEN** 取消该主题的订阅

### 需求：setSubscribe 内部复用 setStringOption

`setSubscribe` 方法内部改为调用 `setStringOption(SocketOption.SUBSCRIBE, topic)`，对外行为不变。

#### 场景：setSubscribe 行为不变
- **WHEN** 调用 `socket.setSubscribe("weather.")`
- **THEN** 行为与修改前完全一致

### 需求：SocketOption 枚举扩展
`SocketOption` 枚举 SHALL 新增以下成员及其对应的 ZMQ 常量值：AFFINITY(4)、IDENTITY(5)、RATE(8)、RECOVERY_IVL(9)、SNDBUF(11)、RCVBUF(12)、MAXMSGSIZE(22)、RECONNECT_IVL(18)、RECONNECT_IVL_MAX(21)、BACKLOG(19)、ROUTER_MANDATORY(33)、TCP_KEEPALIVE(34)、TCP_KEEPALIVE_IDLE(35)、TCP_KEEPALIVE_INTVL(36)、IPV4ONLY(46)、HANDSHAKE_IVL(66)、CONNECT_TIMEOUT(79)、ROUTING_ID(80)、HEARTBEAT_IVL(75)、HEARTBEAT_TIMEOUT(76)、HEARTBEAT_TTL(77)、PROBE_ROUTER(51)、REQ_CORRELATE(52)、REQ_RELAXED(53)。

#### 场景：枚举值与 ZMQ 常量一致
- **WHEN** 访问 `SocketOption.AFFINITY.value` 时
- **THEN** 返回 `4`

#### 场景：枚举值与 ZMQ 常量一致（ROUTING_ID）
- **WHEN** 访问 `SocketOption.ROUTING_ID.value` 时
- **THEN** 返回 `80`

### 需求：Int64 socket 选项读写
系统 SHALL 提供 `setInt64Option(option: SocketOption, value: Int64): Unit` 和 `getInt64Option(option: SocketOption): Int64` 方法，用于 MAXMSGSIZE 等 Int64 类型选项。

#### 场景：设置和读取 MAXMSGSIZE
- **WHEN** 调用 `socket.setInt64Option(SocketOption.MAXMSGSIZE, 1048576)` 后调用 `socket.getInt64Option(SocketOption.MAXMSGSIZE)`
- **THEN** 返回值等于 `1048576`

### 需求：UInt64 socket 选项读写
系统 SHALL 提供 `setUInt64Option(option: SocketOption, value: UInt64): Unit` 和 `getUInt64Option(option: SocketOption): UInt64` 方法，用于 AFFINITY 等 UInt64 类型选项。

#### 场景：设置和读取 AFFINITY
- **WHEN** 调用 `socket.setUInt64Option(SocketOption.AFFINITY, 1)` 后调用 `socket.getUInt64Option(SocketOption.AFFINITY)`
- **THEN** 返回值等于 `1`

### 需求：Binary socket 选项读写
系统 SHALL 提供 `setBinaryOption(option: SocketOption, value: Array<UInt8>): Unit` 和 `getBinaryOption(option: SocketOption): Array<UInt8>` 方法，用于 IDENTITY、ROUTING_ID 等 binary 类型选项。

#### 场景：设置和读取 binary 选项
- **WHEN** 调用 `socket.setBinaryOption(SocketOption.IDENTITY, [1,2,3])` 后调用 `socket.getBinaryOption(SocketOption.IDENTITY)`
- **THEN** 返回值等于 `[1, 2, 3]`

### 需求：setUnsubscribe 便捷方法
系统 SHALL 为 SUB socket 提供 `setUnsubscribe(topic: String): Unit` 方法，内部委托给 `setStringOption(SocketOption.UNSUBSCRIBE, topic)`。

#### 场景：取消订阅特定主题
- **WHEN** 在 SUB Socket 上调用 `socket.setUnsubscribe("weather.")` 时
- **THEN** 通过 `setStringOption` 设置 ZMQ_UNSUBSCRIBE 和主题 "weather."
