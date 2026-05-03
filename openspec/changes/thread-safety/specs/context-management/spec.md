## MODIFIED Requirements

### 需求：ZmqContext 类实现 Resource 接口
系统应当提供 `ZmqContext` 类，实现 `Resource` 接口，包含 `isClosed(): Bool` 和 `close(): Unit` 方法。`close()` SHALL 使用 `AtomicBool.compareAndSwap` 确保底层 `zmq_ctx_term` 只被调用一次。`close()` SHALL 在 `synchronized(mutex)` 块内执行 context 释放和 handle 置空。

#### 场景：创建新的 ZmqContext
- **WHEN** 调用 `ZmqContext()` 时
- **THEN** 通过 `zmq_ctx_new()` 创建新的 ZMQ 上下文，并存储为内部句柄，`closed` 标志初始化为 `false`

#### 场景：ZmqContext 支持 try-with-resources
- **WHEN** 使用 `try (ctx = ZmqContext()) { ... }` 时
- **THEN** 离开代码块时自动调用 `close()`，内部调用 `zmq_ctx_term()`

#### 场景：ZmqContext 的 close 操作是幂等的
- **WHEN** 对已关闭的 ZmqContext 调用 `close()` 时
- **THEN** `compareAndSwap` 返回 `false`，不执行任何操作（不会重复释放）

#### 场景：多线程并发调用 close 只执行一次
- **WHEN** 多个线程同时调用同一 ZmqContext 的 `close()` 时
- **THEN** 只有一个线程的 `compareAndSwap(false, true)` 成功，只有该线程调用 `zmq_ctx_term`，其他线程直接返回

### 需求：ZmqContext 创建 Socket
系统应当在 ZmqContext 上提供 `socket(type_: SocketType): ZmqSocket` 方法，创建新的 ZMQ Socket。`socket()` SHALL 在 `synchronized(mutex)` 块内执行，确保与 `close()` 互斥。

#### 场景：创建 REQ Socket
- **WHEN** 调用 `ctx.socket(SocketType.REQ)` 时
- **THEN** 返回封装了 REQ 类型 zmq_socket 的新 ZmqSocket

#### 场景：创建 REP Socket
- **WHEN** 调用 `ctx.socket(SocketType.REP)` 时
- **THEN** 返回封装了 REP 类型 zmq_socket 的新 ZmqSocket

#### 场景：Socket 创建失败抛出 ZmqError
- **WHEN** `zmq_socket` 返回空指针时
- **THEN** 抛出 `ZmqError` 异常，包含 errno 和错误描述

#### 场景：在 context 关闭后创建 Socket 抛出 ZmqError
- **WHEN** context 已关闭（`closed.load()` 为 `true`）时调用 `ctx.socket(SocketType.REQ)`
- **THEN** 抛出 `ZmqError` 异常（errno=53，ETERM）

#### 场景：socket() 和 close() 互斥执行
- **WHEN** 线程 A 正在执行 `socket()` 且线程 B 同时调用 `close()` 时
- **THEN** 两者通过 `synchronized(mutex)` 互斥执行，`socket()` 要么在 `close()` 之前完成，要么在 `close()` 之后抛出 ZmqError

### 需求：ZmqContext 创建失败抛出异常
系统应当在上下文创建失败时抛出 `ZmqError`。

#### 场景：上下文创建失败
- **WHEN** `zmq_ctx_new()` 返回空指针时
- **THEN** 抛出 `ZmqError` 异常，包含 errno 和错误描述
