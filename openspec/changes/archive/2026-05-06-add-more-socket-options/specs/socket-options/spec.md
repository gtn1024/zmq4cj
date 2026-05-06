## ADDED Requirements

### Requirement: SocketOption 枚举扩展
`SocketOption` 枚举 SHALL 新增以下成员及其对应的 ZMQ 常量值：AFFINITY(4)、IDENTITY(5)、RATE(8)、RECOVERY_IVL(9)、SNDBUF(11)、RCVBUF(12)、MAXMSGSIZE(22)、RECONNECT_IVL(18)、RECONNECT_IVL_MAX(21)、BACKLOG(19)、ROUTER_MANDATORY(33)、TCP_KEEPALIVE(34)、TCP_KEEPALIVE_IDLE(35)、TCP_KEEPALIVE_INTVL(36)、IPV4ONLY(46)、HANDSHAKE_IVL(66)、CONNECT_TIMEOUT(79)、ROUTING_ID(80)、HEARTBEAT_IVL(75)、HEARTBEAT_TIMEOUT(76)、HEARTBEAT_TTL(77)、PROBE_ROUTER(51)、REQ_CORRELATE(52)、REQ_RELAXED(53)。

#### Scenario: 枚举值与 ZMQ 常量一致
- **WHEN** 访问 `SocketOption.AFFINITY.value` 时
- **THEN** 返回 `4`

#### Scenario: 枚举值与 ZMQ 常量一致（ROUTING_ID）
- **WHEN** 访问 `SocketOption.ROUTING_ID.value` 时
- **THEN** 返回 `80`

### Requirement: Int64 socket 选项读写
系统 SHALL 提供 `setInt64Option(option: SocketOption, value: Int64): Unit` 和 `getInt64Option(option: SocketOption): Int64` 方法，用于 MAXMSGSIZE 等 Int64 类型选项。

#### Scenario: 设置和读取 MAXMSGSIZE
- **WHEN** 调用 `socket.setInt64Option(SocketOption.MAXMSGSIZE, 1048576)` 后调用 `socket.getInt64Option(SocketOption.MAXMSGSIZE)`
- **THEN** 返回值等于 `1048576`

### Requirement: UInt64 socket 选项读写
系统 SHALL 提供 `setUInt64Option(option: SocketOption, value: UInt64): Unit` 和 `getUInt64Option(option: SocketOption): UInt64` 方法，用于 AFFINITY 等 UInt64 类型选项。

#### Scenario: 设置和读取 AFFINITY
- **WHEN** 调用 `socket.setUInt64Option(SocketOption.AFFINITY, 1)` 后调用 `socket.getUInt64Option(SocketOption.AFFINITY)`
- **THEN** 返回值等于 `1`

### Requirement: Binary socket 选项读写
系统 SHALL 提供 `setBinaryOption(option: SocketOption, value: Array<UInt8>): Unit` 和 `getBinaryOption(option: SocketOption): Array<UInt8>` 方法，用于 IDENTITY、ROUTING_ID 等 binary 类型选项。

#### Scenario: 设置和读取 ROUTING_ID
- **WHEN** 调用 `socket.setBinaryOption(SocketOption.ROUTING_ID, [1,2,3])` 后调用 `socket.getBinaryOption(SocketOption.ROUTING_ID)`
- **THEN** 返回值等于 `[1, 2, 3]`

### Requirement: setUnsubscribe 便捷方法
系统 SHALL 为 SUB socket 提供 `setUnsubscribe(topic: String): Unit` 方法，内部委托给 `setStringOption(SocketOption.UNSUBSCRIBE, topic)`。

#### Scenario: 取消订阅特定主题
- **WHEN** 在 SUB Socket 上调用 `socket.setUnsubscribe("weather.")` 时
- **THEN** 通过 `setStringOption` 设置 ZMQ_UNSUBSCRIBE 和主题 "weather."
