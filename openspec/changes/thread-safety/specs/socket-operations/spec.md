## MODIFIED Requirements

### 需求：ZmqSocket 类实现 Resource 接口
系统应当提供 `ZmqSocket` 类，实现 `Resource` 接口，包含 `isClosed(): Bool` 和 `close(): Unit` 方法。`close()` SHALL 使用 `AtomicBool.compareAndSwap` 确保底层 `zmq_close` 只被调用一次。

#### 场景：ZmqSocket 支持 try-with-resources
- **WHEN** 使用 `try (socket = ctx.socket(SocketType.REQ)) { ... }` 时
- **THEN** 离开代码块时自动调用 `close()`，内部调用 `zmq_close()`

#### 场景：ZmqSocket 的 close 操作是幂等的
- **WHEN** 对已关闭的 ZmqSocket 调用 `close()` 时
- **THEN** `compareAndSwap` 返回 `false`，不执行任何操作（不会重复释放）

#### 场景：多线程并发调用 close 只执行一次
- **WHEN** 多个线程同时调用同一 ZmqSocket 的 `close()` 时
- **THEN** 只有一个线程的 `compareAndSwap(false, true)` 成功，只有该线程调用 `zmq_close`，其他线程直接返回
