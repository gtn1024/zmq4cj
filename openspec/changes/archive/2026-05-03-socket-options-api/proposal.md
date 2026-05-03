## Why

当前 `SocketOption` 枚举已定义了 LINGER、SNDHWM、RCVTIMEO 等选项，但 `ZmqSocket` 没有公开的 `getOption()`/`setOption()` 方法。用户无法配置超时、水位、延迟等关键参数，实际应用几乎都需要这些配置。

## What Changes

- 在 `ZmqSocket` 中新增 `setIntOption(option: SocketOption, value: Int32): Unit` 方法
- 在 `ZmqSocket` 中新增 `getIntOption(option: SocketOption): Int32` 方法
- 在 `ZmqSocket` 中新增 `setStringOption(option: SocketOption, value: String): Unit` 方法（用于 SUBSCRIBE/UNSUBSCRIBE）
- `setSubscribe` 内部改为调用 `setStringOption`

## Capabilities

### New Capabilities

- `socket-options`: Socket 选项的 get/set API

### Modified Capabilities

- `socket-operations`: 新增 setIntOption、getIntOption、setStringOption 方法

## Impact

- `src/zmq_socket.cj`：新增 3 个公开方法
- `src/zmq_test.cj`：新增测试用例
- 公共 API 扩展，无破坏性变更
