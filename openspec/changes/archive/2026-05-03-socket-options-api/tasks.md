## 1. 实现

- [x] 1.1 在 `src/zmq_socket.cj` 中新增 `setIntOption(option: SocketOption, value: Int32): Unit` 方法
- [x] 1.2 在 `src/zmq_socket.cj` 中新增 `getIntOption(option: SocketOption): Int32` 方法
- [x] 1.3 在 `src/zmq_socket.cj` 中新增 `setStringOption(option: SocketOption, value: String): Unit` 方法
- [x] 1.4 重构 `setSubscribe` 方法，内部改为调用 `setStringOption`

## 2. 测试

- [x] 2.1 新增测试：setIntOption/getIntOption 设置并读取 LINGER
- [x] 2.2 新增测试：RCVTIMEO 超时生效（recv 超时后抛出 EAGAIN）
- [x] 2.3 新增测试：setStringOption UNSUBSCRIBE 取消订阅
- [x] 2.4 确认全部现有测试通过（setSubscribe 行为不变）
