## 1. 实现 unbind/disconnect 方法

- [x] 1.1 在 `ZmqSocket` 中新增 `unbind(addr: String): Unit` 方法，封装 `zmq_unbind` FFI 调用
- [x] 1.2 在 `ZmqSocket` 中新增 `disconnect(addr: String): Unit` 方法，封装 `zmq_disconnect` FFI 调用

## 2. 测试

- [x] 2.1 新增 unbind 测试：bind 后 unbind 成功，unbind 不存在的端点抛出 ZmqError
- [x] 2.2 新增 disconnect 测试：connect 后 disconnect 成功，disconnect 不存在的端点抛出 ZmqError
- [x] 2.3 运行 `cjpm test` 确认全部通过
