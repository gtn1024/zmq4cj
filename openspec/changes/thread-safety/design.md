## Context

zmq4cj 当前 `ZmqContext` 和 `ZmqSocket` 的 `close()` 使用非原子的 check-then-act 模式：

```cangjie
public func close(): Unit {
    if (isClosed()) { return }
    unsafe { zmq_close(handle) }
    handle = CPointer<Unit>()
}
```

多线程同时调用时，两个线程都能通过 `isClosed()` 检查，导致底层 C 函数被调用两次（double-free）。`ZmqContext.socket()` 在 `close()` 竞态下可能使用已释放的 context handle。

调研主流 ZMQ 绑定后发现：
- 所有绑定都不对 send/recv 加锁
- JeroMQ 和 NetMQ 用 `AtomicBoolean.compareAndSet` 保护 close()
- czmq 用 mutex 保护 socket 创建/销毁

仓颉标准库提供 `std.sync.AtomicBool`（含 `compareAndSwap`）和 `std.sync.Mutex`（可重入），以及 `synchronized` 关键字。

## Goals / Non-Goals

**Goals:**
- `close()` 只执行一次底层 C 清理调用，防止 double-free
- `socket()` 不会在 context 已关闭后使用 stale handle
- 文档明确 ZmqSocket 不是线程安全的

**Non-Goals:**
- 不给 send/recv/bind/connect 加锁
- 不实现 socket 迁移机制
- 不实现线程安全的 poll 或异步 API

## Decisions

### D1：AtomicBool 保护 close() 幂等性

**选择**：`std.sync.AtomicBool` 的 `compareAndSwap(false, true)` 确保 `close()` 只执行一次

**替代方案**：
- `Mutex` 保护整个 `close()` → 过重
- 检查 handle 是否为 null → 非原子操作，仍有竞态

**理由**：`compareAndSwap` 是原子操作，只有一个线程能成功交换。与 JeroMQ (`AtomicBoolean.compareAndSet`) 和 NetMQ (`Interlocked.CompareExchange`) 模式一致。

### D2：Mutex 保护 ZmqContext 的 close() 和 socket()

**选择**：`ZmqContext` 使用 `Mutex` + `synchronized` 保护 `close()` 和 `socket()` 的临界区

**替代方案**：
- 仅用 AtomicBool → 不足以防止 socket() 和 close() 之间的竞态
- 不保护 → 当前的 bug

**理由**：`socket()` 和 `close()` 之间存在竞态——线程 A 通过 `isClosed()` 检查后，线程 B 可能执行 `close()` 释放 context。需要互斥保证两者互斥执行。仓颉 `Mutex` 是可重入的，`synchronized` 关键字自动管理 lock/unlock。

### D3：send/recv 不加锁

**选择**：`send`、`recv`、`bind`、`connect` 等操作不加锁

**理由**：所有主流 ZMQ 绑定都不对 socket 操作加锁。ZMQ 的设计哲学是每个 socket 由一个线程独占。加锁会引入不必要的性能开销。

### D4：文档说明线程安全约束

**选择**：在 README 中添加"线程安全"章节

## Risks / Trade-offs

- **[仓颉 AtomicBool 可靠性]** → 仓颉是较新语言，但 `std.sync` 是标准库核心，`AtomicBool` 是基础原语，风险低
- **[Mutex 重入]** → 仓颉 `Mutex` 是可重入的，`synchronized` 自动管理，不会死锁
- **[性能]** → close() 和 socket() 是低频操作，开销可忽略
