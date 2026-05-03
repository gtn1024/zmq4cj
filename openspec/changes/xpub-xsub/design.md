## Approach

XPUB/XSUB 是 libzmq 原生支持的 Socket 类型，无需新增 FFI 声明。只需在 `SocketType` 枚举中添加值，并编写测试验证功能。

## Key Decisions

1. **SocketType 新增 XPUB(9)、XSUB(10)、STREAM(11)** — 值与 libzmq C 常量一致
2. **XPUB/XSUB 行为**：XSUB 订阅转发给 XPUB，XPUB 收到消息后分发给所有匹配的 SUB/XSUB
3. **STREAM 类型** — 仅加枚举值，暂不暴露特殊 API（`zmq_msg_group`/`zmq_msg_routing_id` 等需要独立 change）

## Impact

- `src/zmq_types.cj`：SocketType 枚举新增 3 个值
- `src/zmq_test.cj`：新增 XPUB/XSUB 测试
- `README.md` / `README-zh.md`：SocketType 表格新增 3 行
- `AGENTS.md`：无需改动（已覆盖通用说明）
