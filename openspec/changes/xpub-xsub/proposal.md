## Why

zmq4cj 目前只支持基础 Socket 类型（PUB/SUB、REQ/REP 等），缺少 XPUB/XSUB 和 STREAM 类型。XPUB/XSUB 是高级发布-订阅模式的关键组件，支持订阅转发和代理（proxy）场景。主流 ZeroMQ 绑定（zmq.rs、pyzmq）均支持这些类型。

## What Changes

- 在 `SocketType` 枚举中新增 XPUB(9)、XSUB(10)、STREAM(11)
- 为 XPUB/XSUB 编写测试用例（订阅转发、代理拓扑）
- 更新 README（中英文）和 AGENTS.md
