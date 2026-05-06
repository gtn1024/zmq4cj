## Why

当前 `SocketOption` 枚举只包含 8 个选项（SUBSCRIBE、UNSUBSCRIBE、RCVMORE、LINGER、SNDHWM、RCVHWM、RCVTIMEO、SNDTIMEO），缺少多个 libzmq 常用选项。用户无法设置 socket 身份、连接重试策略、消息大小限制、亲和性等关键参数，限制了实际生产场景的使用。

## What Changes

在 `SocketOption` 枚举中新增以下选项（按常用程度排列）：

**整数型选项（通过现有 `setIntOption`/`getIntOption` 即可使用）：**
- `AFFINITY`（线程亲和性，UInt64，值 4）— *需要新增 UInt64 读写方法*
- `IDENTITY`（socket 身份，binary，值 5）— *需要新增 binary 读写方法*
- `MAXMSGSIZE`（最大消息大小，Int64，值 22）— *需要新增 Int64 读写方法*
- `RATE`（多播速率，Int32，值 8）
- `RECOVERY_IVL`（多播恢复间隔，Int32，值 9）
- `SNDBUF`（发送缓冲区大小，Int32，值 11）
- `RCVBUF`（接收缓冲区大小，Int32，值 12）
- `RECONNECT_IVL`（重连间隔，Int32，值 18）
- `RECONNECT_IVL_MAX`（最大重连间隔，Int32，值 21）
- `BACKLOG`（连接队列长度，Int32，值 19）
- `TCP_KEEPALIVE`（TCP 保活策略，Int32，值 34）
- `TCP_KEEPALIVE_IDLE`（TCP 保活空闲时间，Int32，值 35）
- `TCP_KEEPALIVE_INTVL`（TCP 保活间隔，Int32，值 36）
- `IPV4ONLY`（仅 IPv4，Int32，值 46）
- `ROUTER_MANDATORY`（ROUTER 严格模式，Int32，值 33）
- `PROBE_ROUTER`（连接时探测 ROUTER，Int32，值 51）
- `REQ_CORRELATE`（REQ 请求关联，Int32，值 52）
- `REQ_RELAXED`（REQ 宽松模式，Int32，值 53）
- `ROUTING_ID`（路由 ID，binary，值 80）— *ZMQ 4.2+ 替代 IDENTITY*
- `CONNECT_TIMEOUT`（连接超时，Int32，值 79）
- `HANDSHAKE_IVL`（握手间隔，Int32，值 66）
- `HEARTBEAT_IVL`（心跳间隔，Int32，值 75）
- `HEARTBEAT_TIMEOUT`（心跳超时，Int32，值 76）
- `HEARTBEAT_TTL`（心跳 TTL，Int32，值 77）

**便捷方法：**
- `setUnsubscribe(topic: String)` — 取消订阅

## Capabilities

### New Capabilities

_无_

### Modified Capabilities

- `socket-options`: 新增 ~25 个 `SocketOption` 枚举值及对应的 `Int64`/`UInt64`/`binary` 读写支持

## Impact

- `src/zmq_types.cj`：`SocketOption` 枚举新增成员
- `src/zmq_socket.cj`：新增 `setInt64Option`/`getInt64Option`、`setUInt64Option`/`getUInt64Option`、`setBinaryOption`/`getBinaryOption` 方法
- `src/zmq_test.cj`：新增测试
- 纯新增，非破坏性变更
