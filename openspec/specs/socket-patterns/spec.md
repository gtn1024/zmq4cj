## 新增需求

### 需求：REQ/REP 模式端到端工作
系统应当支持 REQ 和 REP Socket 类型的请求-应答模式。

#### 场景：REQ 发送，REP 接收并回复
- **当** REP Socket 绑定到 `tcp://*:5555`，REQ Socket 连接到 `tcp://localhost:5555`
- **且** REQ Socket 发送 "Hello"
- **且** REP Socket 接收消息并发送回 "World"
- **则** REQ Socket 接收到 "World"

#### 场景：REQ/REP 消息内容保持完整
- **当** 通过 REQ Socket 发送 "Hello" 时
- **则** REP Socket 接收到 `[72, 101, 108, 108, 111]`

### 需求：PUB/SUB 模式端到端工作
系统应当支持 PUB 和 SUB Socket 类型的发布-订阅模式。

#### 场景：PUB 发布，SUB 带主题过滤接收
- **当** PUB Socket 绑定到 `tcp://*:5556`
- **且** SUB Socket 连接并订阅 "weather." 主题
- **且** PUB Socket 发送 "weather.temp=25"
- **则** SUB Socket 接收到 "weather.temp=25"

#### 场景：SUB 过滤不匹配的消息
- **当** SUB Socket 订阅 "weather."
- **且** PUB Socket 发送 "news.headline=..."
- **则** SUB Socket 不会接收到不匹配的消息

#### 场景：SUB 订阅所有消息
- **当** SUB Socket 使用空主题 `setSubscribe("")` 订阅时
- **则** SUB Socket 接收所有发布的消息

### 需求：PUSH/PULL 模式端到端工作
系统应当支持 PUSH 和 PULL Socket 类型的推送-拉取模式。

#### 场景：PUSH 发送，PULL 接收
- **当** PULL Socket 绑定到 `tcp://*:5557`，PUSH Socket 连接
- **且** PUSH Socket 发送 "task-1"
- **则** PULL Socket 接收到 "task-1"

#### 场景：PUSH/PULL 负载均衡
- **当** 两个 PULL Socket 连接到一个 PUSH Socket
- **且** PUSH Socket 发送 10 条消息
- **则** 消息在两个 PULL Socket 之间分配（各约 5 条）

### 需求：DEALER/ROUTER 模式端到端工作
系统应当支持 DEALER-ROUTER 模式。

#### 场景：DEALER 发送，ROUTER 带身份标识接收
- **当** ROUTER Socket 已绑定，DEALER Socket 已连接
- **且** DEALER 发送 "message"
- **则** ROUTER 接收到消息，前面附带 DEALER 的身份帧

### 需求：PAIR 模式端到端工作
系统应当支持 PAIR Socket 类型的双向通信。

#### 场景：PAIR Socket 互相交换消息
- **当** 两个 PAIR Socket 通过 inproc 传输连接
- **且** PAIR-A 发送 "ping"
- **则** PAIR-B 接收到 "ping"
- **且** PAIR-B 可以发送 "pong" 回 PAIR-A
