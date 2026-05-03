## 1. FFI 与类型

- [ ] 1.1 在 `src/zmq_ffi.cj` 中声明 `zmq_poll(items: CPointer<Unit>, nitems: Int32, timeout: Int64): Int32`
- [ ] 1.2 在 `src/zmq_types.cj` 中新增 `PollEvent` 枚举（POLLIN=1, POLLOUT=2, POLLERR=4）

## 2. 核心实现

- [ ] 2.1 新增 `src/zmq_poll.cj`，实现 `PollItem` 类（socket, events, revents）
- [ ] 2.2 在 `src/zmq_poll.cj` 中实现 `ZmqPoll.poll(items, timeout): Int32` 静态方法：malloc pollitem 数组 → 填充 → 调用 zmq_poll → 读回 revents → free

## 3. 测试

- [ ] 3.1 新增测试：单个 socket POLLIN，有消息时 revents 包含 POLLIN
- [ ] 3.2 新增测试：超时返回 0，revents 不变
- [ ] 3.3 新增测试：同时监听两个 socket，只有一个有消息
- [ ] 3.4 确认全部现有测试通过
