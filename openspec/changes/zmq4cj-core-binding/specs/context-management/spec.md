## 新增需求

### 需求：ZmqContext 类实现 Resource 接口
系统应当提供 `ZmqContext` 类，实现 `Resource` 接口，包含 `isClosed(): Bool` 和 `close(): Unit` 方法。

#### 场景：创建新的 ZmqContext
- **当** 调用 `ZmqContext()` 时
- **则** 通过 `zmq_ctx_new()` 创建新的 ZMQ 上下文，并存储为内部句柄

#### 场景：ZmqContext 支持 try-with-resources
- **当** 使用 `try (ctx = ZmqContext()) { ... }` 时
- **则** 离开代码块时自动调用 `close()`，内部调用 `zmq_ctx_term()`

#### 场景：ZmqContext 的 close 操作是幂等的
- **当** 对已关闭的 ZmqContext 调用 `close()` 时
- **则** 不执行任何操作（不会重复释放）

### 需求：ZmqContext 创建 Socket
系统应当在 ZmqContext 上提供 `socket(type_: SocketType): ZmqSocket` 方法，创建新的 ZMQ Socket。

#### 场景：创建 REQ Socket
- **当** 调用 `ctx.socket(SocketType.REQ)` 时
- **则** 返回封装了 REQ 类型 zmq_socket 的新 ZmqSocket

#### 场景：创建 REP Socket
- **当** 调用 `ctx.socket(SocketType.REP)` 时
- **则** 返回封装了 REP 类型 zmq_socket 的新 ZmqSocket

#### 场景：Socket 创建失败抛出 ZmqError
- **当** `zmq_socket` 返回空指针时
- **则** 抛出 `ZmqError` 异常，包含 errno 和错误描述

### 需求：ZmqContext 创建失败抛出异常
系统应当在上下文创建失败时抛出 `ZmqError`。

#### 场景：上下文创建失败
- **当** `zmq_ctx_new()` 返回空指针时
- **则** 抛出 `ZmqError` 异常，包含 errno 和错误描述
