## Context

`ZmqSocket` 通过 FFI 封装了 libzmq 的 socket 操作，目前提供 `bind()` 和 `connect()`。FFI 层（`zmq_ffi.cj`）已声明 `zmq_unbind` 和 `zmq_disconnect`，但未在公开 API 层暴露。封装模式与现有 `bind`/`connect` 一致：调用 FFI → 检查返回值 → 失败抛 `ZmqError`。

## Goals / Non-Goals

**Goals:**

- 在 `ZmqSocket` 中新增 `unbind(endpoint: String)` 和 `disconnect(endpoint: String)` 公开方法
- 遵循现有 `bind`/`connect` 的封装模式（unsafe FFI 调用 + checkResult）
- 新增测试覆盖正常和异常场景

**Non-Goals:**

- 不跟踪已绑定/已连接端点列表（用户自行管理）
- 不修改 FFI 层（已有声明）
- 不添加异步版本

## Decisions

- **方法签名与 bind/connect 对称**：`unbind(endpoint: String)` 和 `disconnect(endpoint: String)`，无返回值，失败抛 `ZmqError`。与现有 API 风格一致。
- **不做端点跟踪**：不维护内部端点列表。用户负责传入正确的端点字符串。这与 libzmq C API 行为一致，避免状态不同步问题。

## Risks / Trade-offs

- **[端点不存在]** → libzmq 返回错误，`checkResult` 抛 `ZmqError`，行为与 C API 一致，符合预期。
