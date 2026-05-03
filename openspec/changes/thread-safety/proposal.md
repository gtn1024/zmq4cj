## Why

ZmqContext.close() 和 ZmqSocket.close() 存在 check-then-act 竞态：多线程同时调用时都能通过 isClosed() 检查，导致底层 C 函数被调用两次（double-free）。ZmqContext.socket() 在 close() 竞态下可能使用已释放的 context handle。此外，libzmq socket 本身不是线程安全的，但 API 未做任何约束或文档说明。

## What Changes

- ZmqSocket.close() 添加 AtomicBool.compareAndSwap 原子保护，确保只执行一次
- ZmqContext.close() 添加 AtomicBool.compareAndSwap 原子保护
- ZmqContext.socket() 和 close() 添加 Mutex + synchronized 互斥，防止 socket() 使用已释放的 context
- 在 README 中添加线程安全章节，说明 ZmqSocket 不是线程安全的

## Capabilities

### New Capabilities
（无新增能力）

### Modified Capabilities
- `context-management`：ZmqContext.close() 和 socket() 添加线程安全保护（AtomicBool + Mutex）
- `socket-operations`：ZmqSocket.close() 添加 AtomicBool 原子保护

## Impact

- **API 兼容性**：完全兼容，不改变公共 API 签名
- **新增依赖**：`std.sync.AtomicBool`、`std.sync.Mutex`（仓颉标准库，无外部依赖）
- **性能**：close() 和 socket() 增加极小的锁开销（低频操作，无影响）
- **send/recv 不加锁**：遵循 libzmq 和所有主流绑定的设计哲学
