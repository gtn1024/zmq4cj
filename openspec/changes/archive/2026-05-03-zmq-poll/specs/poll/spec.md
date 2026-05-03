## ADDED Requirements

### Requirement: PollItem 类

系统应当提供 `PollItem` 类，封装一个 socket 及其感兴趣的事件。

#### Scenario: 创建 PollItem 监听可读事件
- **WHEN** 创建 `PollItem(socket, PollEvent.POLLIN.value)`
- **THEN** events 为 POLLIN，revents 为 0

#### Scenario: poll 后 revents 被填充
- **WHEN** PollItem 的 socket 有消息到达且调用了 `ZmqPoll.poll()`
- **THEN** `item.revents` 包含 POLLIN 标志

### Requirement: PollEvent 枚举

系统应当提供 `PollEvent` 枚举，定义 POLLIN(1)、POLLOUT(2)、POLLERR(4) 三个事件常量。

#### Scenario: PollEvent 值与 libzmq 常量一致
- **WHEN** 访问 `PollEvent.POLLIN.value`
- **THEN** 返回 1

### Requirement: ZmqPoll.poll 静态方法

系统应当提供 `ZmqPoll.poll(items: Array<PollItem>, timeout: Int64): Int32` 静态方法。

#### Scenario: 监听单个 socket 可读事件
- **WHEN** 创建一个监听 POLLIN 的 PollItem，socket 有消息待接收，调用 `poll(items, -1)`
- **THEN** 返回 1，`items[0].revents` 包含 POLLIN

#### Scenario: 超时返回 0
- **WHEN** 创建一个 PollItem 但 socket 无消息，调用 `poll(items, 100)`（100ms 超时）
- **THEN** 返回 0

#### Scenario: 同时监听多个 socket
- **WHEN** 创建两个 PollItem（分别监听不同 socket），只有第一个有消息
- **THEN** 返回 1，只有第一个的 revents 包含 POLLIN

#### Scenario: poll 错误抛出 ZmqError
- **WHEN** 传入已关闭的 socket
- **THEN** 抛出 ZmqError

### Requirement: zmq_poll FFI 声明

`zmq_ffi.cj` 应当声明 `zmq_poll` 函数。

#### Scenario: zmq_poll 可被调用
- **WHEN** 通过 FFI 调用 `zmq_poll`
- **THEN** 编译和链接成功
