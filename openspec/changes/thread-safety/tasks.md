## 1. ZmqSocket close() 原子保护

- [x] 1.1 在 `ZmqSocket` 中添加 `import std.sync.AtomicBool`
- [x] 1.2 新增 `let closed = AtomicBool(false)` 字段
- [x] 1.3 重写 `close()`：使用 `closed.compareAndSwap(false, true)` 确保只执行一次
- [x] 1.4 更新 `isClosed()`：返回 `closed.load()`

## 2. ZmqContext close() 和 socket() 线程安全

- [ ] 2.1 在 `ZmqContext` 中添加 `import std.sync.{AtomicBool, Mutex}`
- [ ] 2.2 新增 `let closed = AtomicBool(false)` 和 `let mutex = Mutex()` 字段
- [ ] 2.3 重写 `close()`：先用 `compareAndSwap` 防重入，再用 `synchronized(mutex)` 保护 `zmq_ctx_term` 和 handle 置空
- [ ] 2.4 更新 `isClosed()`：返回 `closed.load()`
- [ ] 2.5 重写 `socket()`：用 `synchronized(mutex)` 保护整个方法体（检查 closed + 创建 socket）

## 3. 验证

- [ ] 3.1 确认 `cjpm build` 编译通过
- [ ] 3.2 确认 `cjpm test` 所有现有测试通过（REQ/REP、PUB/SUB、PUSH/PULL、DEALER/ROUTER、PAIR、multipart）

## 4. 文档

- [ ] 4.1 在 README 中添加"线程安全"章节，说明 ZmqContext 的 close()/socket() 线程安全，ZmqSocket 不线程安全
- [ ] 4.2 更新 AGENTS.md 中的架构说明，标注线程安全设计
