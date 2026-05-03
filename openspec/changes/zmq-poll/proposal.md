## Why

当前 zmq4cj 只支持阻塞式 recv，无法同时监听多个 socket 或设置超时等待。实际应用中，常见需求包括：
- 同时监听多个 socket（如 REQ + SUB）
- 带超时的消息接收（避免无限阻塞）
- 实现事件循环

libzmq 提供了 `zmq_poll` API 来解决这些问题，需要将其暴露给仓颉用户。

## What Changes

- 新增 `PollItem` 数据类，封装 socket + 事件掩码 + 返回事件
- 新增 `ZmqPoll.poll(items: Array<PollItem>, timeout: Int64): Int32` 静态方法
- 新增 `PollEvent` 枚举（POLLIN / POLLOUT / POLLERR）
- 在 `zmq_ffi.cj` 中声明 `zmq_poll` FFI 函数

## Capabilities

### New Capabilities

- `poll`: zmq_poll 轮询 API，支持多 socket 事件监听和超时

## Impact

- `src/zmq_ffi.cj`：新增 zmq_poll FFI 声明
- `src/zmq_types.cj`：新增 PollEvent 枚举
- 新增 `src/zmq_poll.cj`：PollItem 类和 ZmqPoll 静态方法
- `src/zmq_test.cj`：新增 poll 相关测试
- 公共 API 扩展，无破坏性变更
