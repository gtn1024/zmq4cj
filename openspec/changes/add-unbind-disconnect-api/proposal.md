## Why

ZmqSocket 只暴露了 `bind()` 和 `connect()`，但缺少 `unbind()` 和 `disconnect()`。用户无法在运行时动态移除已绑定或已连接的端点，限制了动态拓扑场景（如服务发现、热替换）。FFI 层已声明 `zmq_unbind` 和 `zmq_disconnect`，封装成本极低。

## What Changes

- 在 `ZmqSocket` 公开 API 中新增 `unbind(endpoint: String)` 方法
- 在 `ZmqSocket` 公开 API 中新增 `disconnect(endpoint: String)` 方法
- 新增对应单元测试

## Capabilities

### New Capabilities

_无_

### Modified Capabilities

- `socket-operations`: 新增 unbind 和 disconnect 操作的公开 API 及测试

## Impact

- `src/zmq_socket.cj`：新增两个公开方法
- `src/zmq_test.cj`：新增测试用例
- 公开 API 变更（纯新增，非破坏性）
