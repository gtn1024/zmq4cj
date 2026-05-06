## ADDED Requirements

### Requirement: ZmqSocket unbind 操作
系统 SHALL 提供 `unbind(addr: String): Unit` 方法，解除已绑定的端点。

#### Scenario: 成功解除绑定
- **WHEN** 调用 `socket.unbind("tcp://*:5555")` 且该端点之前已通过 `bind()` 绑定
- **THEN** 调用 `zmq_unbind`，成功时不抛出异常

#### Scenario: unbind 端点不存在时抛出 ZmqError
- **WHEN** 调用 `socket.unbind("tcp://*:9999")` 且该端点未被绑定
- **THEN** `zmq_unbind` 返回 -1，抛出 `ZmqError` 异常

### Requirement: ZmqSocket disconnect 操作
系统 SHALL 提供 `disconnect(addr: String): Unit` 方法，断开已连接的端点。

#### Scenario: 成功断开连接
- **WHEN** 调用 `socket.disconnect("tcp://localhost:5555")` 且该端点之前已通过 `connect()` 连接
- **THEN** 调用 `zmq_disconnect`，成功时不抛出异常

#### Scenario: disconnect 端点不存在时抛出 ZmqError
- **WHEN** 调用 `socket.disconnect("tcp://localhost:9999")` 且该端点未被连接
- **THEN** `zmq_disconnect` 返回 -1，抛出 `ZmqError` 异常
