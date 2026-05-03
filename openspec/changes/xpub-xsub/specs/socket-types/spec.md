## ADDED Requirements

### Requirement: SocketType 新增 XPUB、XSUB、STREAM

`SocketType` 枚举应包含 XPUB(9)、XSUB(10)、STREAM(11)，值与 libzmq 常量一致。

#### Scenario: XPUB/XSUB 订阅转发
- **GIVEN** 一个 XSUB 连接到 XPUB，一个 SUB 连接到 XPUB
- **WHEN** SUB 发送订阅消息给 XSUB，XSUB 转发给 XPUB
- **THEN** 通过 XPUB 发送的消息能被 SUB 接收到

#### Scenario: XPUB/XSUB 消息分发
- **GIVEN** XSUB → XPUB → SUB 拓扑已建立并订阅
- **WHEN** 通过 XSUB 发送消息
- **THEN** SUB 能收到该消息

#### Scenario: STREAM 类型可创建
- **WHEN** 调用 `ctx.socket(SocketType.STREAM)`
- **THEN** 返回有效的 ZmqSocket 实例
