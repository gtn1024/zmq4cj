## 1. FFI 层

- [x] 1.1 在 `zmq_ffi.cj` 添加 `zmq_proxy` 和 `zmq_proxy_steerable` foreign func 声明

## 2. 公共 API

- [x] 2.1 创建 `src/zmq_proxy.cj`，实现 `ZmqProxy` 类，提供 `start()` 和 `startSteerable()` 静态方法
- [x] 2.2 ETERM 错误码（78）特殊处理：context 终止时不抛异常，正常返回

## 3. 测试

- [x] 3.1 添加 XPUB/XSUB 代理转发消息测试（多线程，验证消息正确转发）
- [x] 3.2 添加 zmq_proxy_steerable 可控制代理终止测试
- [x] 3.3 添加错误处理测试（传入已关闭 socket 抛 ZmqError）
