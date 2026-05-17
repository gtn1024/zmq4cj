## Context

zmq4cj 目前提供 ZmqContext、ZmqSocket、ZmqPoll 三个公共 API，支持所有主要 socket 类型和选项。缺少 `zmq_proxy` 和 `zmq_proxy_steerable` — 这是 libzmq 内置的代理函数，用于在两个 socket 之间转发消息，是构建消息代理（如 XPUB/XSUB 中继）的核心 API。

libzmq 提供两个 C 函数：
- `zmq_proxy(frontend, backend, capture)` — 阻塞式代理，直到 context 被终止才返回
- `zmq_proxy_steerable(frontend, backend, capture, control)` — 可通过 control socket 发送命令控制

ZmqSocket 的 `handle` 字段是 `var` 且 internal 可见，ZmqProxy 需要访问它来获取底层 C 指针。

## Goals / Non-Goals

**Goals:**
- 封装 `zmq_proxy` 和 `zmq_proxy_steerable`，提供安全的仓颉 API
- 支持阻塞式代理（前台运行）和可控制代理
- 通过 `ZmqError` 异常报告错误
- 与现有 ZmqSocket/ZmqContext API 无缝集成

**Non-Goals:**
- 不实现异步代理（可在未来通过仓颉协程实现）
- 不封装 `zmq_proxy_steerable` 的 STATISTICS 命令（DRAFT API）
- 不修改现有 ZmqSocket API

## Decisions

### 1. ZmqProxy 使用静态方法而非实例

**选择**: `ZmqProxy` 作为无状态的静态工具类，提供 `start()` 和 `startSteerable()` 静态方法。

**理由**: zmq_proxy 是阻塞调用，不持有状态。静态方法更简洁，与 ZmqPoll 的设计风格一致。

**替代方案**: 实例化 ZmqProxy — 过度设计，proxy 函数无状态。

### 2. 参数设计

**选择**:
- `start(frontend: ZmqSocket, backend: ZmqSocket, capture?: ZmqSocket)`
- `startSteerable(frontend: ZmqSocket, backend: ZmqSocket, capture?: ZmqSocket, control: ZmqSocket)`

capture 为可选参数（nullable），对应 C API 的 NULL。control 为必需参数。

**理由**: 与 C API 保持对称，但使用 nullable 替代 NULL 指针，类型安全。

### 3. 访问 ZmqSocket 底层 handle

**选择**: 通过 `socket.handle` 直接访问。`handle` 是 `var` 包级可见字段（同一 package 内可访问）。

**理由**: ZmqProxy 和 ZmqSocket 在同一 package `zmq` 内，可直接访问 internal 字段，无需额外暴露。

### 4. 错误处理

**选择**: zmq_proxy 返回 -1 时抛出 ZmqError，与现有 API 风格一致。ETERM（context 终止）也会导致 proxy 返回 -1。

**理由**: 统一的错误处理模式。

## Risks / Trade-offs

- **[阻塞调用]** zmq_proxy 是阻塞的，调用后会占据线程 → 文档说明，未来可通过协程实现非阻塞版本
- **[Socket 生命周期]** proxy 运行期间 socket 不能被关闭 → 调用者需保证 socket 生命周期，与 C API 行为一致
