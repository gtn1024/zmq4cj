### Requirement: zmq_proxy 基本代理功能
ZmqProxy SHALL 提供 `start(frontend, backend, capture?)` 静态方法，封装 `zmq_proxy` C 函数，在 frontend 和 backend 之间转发消息。

#### Scenario: XPUB/XSUB 代理转发消息
- **WHEN** 创建 XSUB 和 XPUB socket，XSUB bind 到 `tcp://*:5560`，XPUB bind 到 `tcp://*:5561`
- **且** 在另一个线程启动 `ZmqProxy.start(xsub, xpub)`
- **且** PUB socket 连接到 `tcp://localhost:5560`，SUB socket 连接到 `tcp://localhost:5561` 并订阅
- **且** PUB 发送 "test-message"
- **THEN** SUB socket 接收到 "test-message"

#### Scenario: 代理不带 capture socket
- **WHEN** 调用 `ZmqProxy.start(frontend, backend)` 不传 capture 参数
- **THEN** proxy 正常转发消息，不捕获

#### Scenario: 代理 context 终止时返回
- **WHEN** proxy 正在运行
- **且** ZmqContext 被终止（term）
- **THEN** proxy 正常返回，不抛出异常（ETERM 是正常终止信号）

### Requirement: zmq_proxy_steerable 可控制代理
ZmqProxy SHALL 提供 `startSteerable(frontend, backend, capture?, control)` 静态方法，封装 `zmq_proxy_steerable` C 函数，支持通过 control socket 发送命令控制代理。

#### Scenario: 通过 TERMINATE 命令终止代理
- **WHEN** 创建可控制代理 `ZmqProxy.startSteerable(frontend, backend, control: controlSocket)`
- **且** 代理正在运行
- **且** 向 control socket 发送 "TERMINATE" 命令
- **THEN** 代理正常终止并返回

### Requirement: 错误处理
ZmqProxy 方法 SHALL 在 zmq_proxy/zmq_proxy_steerable 返回 -1 时抛出 ZmqError 异常（ETERM 除外，context 终止是正常行为）。

#### Scenario: 传入已关闭的 socket
- **WHEN** 调用 `ZmqProxy.start(closedSocket, backend)`
- **THEN** 抛出 ZmqError 异常
