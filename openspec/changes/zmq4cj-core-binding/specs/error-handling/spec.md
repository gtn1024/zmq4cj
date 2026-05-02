## 新增需求

### 需求：ZmqError 异常类
系统应当提供 `ZmqError` 类，继承 `Exception`，包含 `errno: Int32` 和 `message: String` 字段。

#### 场景：ZmqError 携带来自 zmq_errno 的 errno
- **当** ZMQ 操作失败并抛出 ZmqError 时
- **则** `errno` 字段包含来自 `zmq_errno()` 的值

#### 场景：ZmqError 的 message 来自 zmq_strerror
- **当** 使用 errno 值构造 ZmqError 时
- **则** `message` 字段包含来自 `zmq_strerror(errno)` 的字符串

### 需求：所有 FFI 失败都抛出 ZmqError
每个可能失败的 FFI 调用都应当检查返回值，失败时抛出 `ZmqError`。

#### 场景：zmq_bind 返回 -1
- **当** `zmq_bind` 返回 -1 时
- **则** 抛出 `ZmqError`，包含当前 errno

#### 场景：zmq_send 返回 -1
- **当** `zmq_send` 返回 -1 时
- **则** 抛出 `ZmqError`，包含当前 errno

#### 场景：zmq_recv 返回 -1
- **当** `zmq_recv` 返回 -1 时
- **则** 抛出 `ZmqError`，包含当前 errno

### 需求：不向库用户暴露 unsafe
公开 API 不应当向用户暴露 `unsafe` 块、`CPointer` 或 `CString` 类型。

#### 场景：用户代码使用 ZmqContext 无需 unsafe
- **当** 用户创建 `ZmqContext` 并调用 `socket()`、`bind()`、`send()`、`recv()` 时
- **则** 这些方法均不要求用户编写 `unsafe` 块

#### 场景：用户代码使用 ZmqSocket 不涉及 CPointer
- **当** 用户调用 `send(data: Array<UInt8>)` 和 `recv(): Array<UInt8>` 时
- **则** 方法签名和返回类型中不出现 CPointer 类型
