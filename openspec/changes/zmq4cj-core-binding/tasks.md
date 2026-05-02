## 1. 构建系统搭建

- [x] 1.1 将 libzmq 作为 git submodule 添加到 `vendor/libzmq/`
- [x] 1.2 创建 `build.cj`，在 `pre-build` 钩子中从源码编译 libzmq（cmake + make）
- [x] 1.3 配置 `cjpm.toml`，设置 `[ffi.c]` 和各平台的 `[target.*.ffi.c]` 路径
- [x] 1.4 将 `vendor/build/` 添加到 `.gitignore`
- [x] 1.5 验证 `cjpm build` 能成功编译 libzmq.a 并链接

## 2. FFI 声明

- [x] 2.1 创建 `src/zmq_ffi.cj`，声明上下文管理函数（zmq_ctx_new, zmq_ctx_term, zmq_ctx_set, zmq_ctx_get）
- [x] 2.2 添加 Socket 管理 FFI 声明（zmq_socket, zmq_close, zmq_setsockopt, zmq_getsockopt）
- [x] 2.3 添加连接 FFI 声明（zmq_bind, zmq_connect, zmq_unbind, zmq_disconnect）
- [x] 2.4 添加消息收发 FFI 声明（zmq_send, zmq_recv）
- [x] 2.5 添加错误处理 FFI 声明（zmq_errno, zmq_strerror）
- [x] 2.6 验证所有类型映射正确（void* → CPointer<Unit>, size_t → UIntNative, int → Int32, const char* → CString）

## 3. 类型与常量

- [x] 3.1 创建 `src/zmq_types.cj`，定义 `SocketType` 枚举（PAIR=0, PUB=1, SUB=2, REQ=3, REP=4, DEALER=5, ROUTER=6, PULL=7, PUSH=8）
- [x] 3.2 添加 `SocketOption` 枚举（SUBSCRIBE=6, UNSUBSCRIBE=7, LINGER=17, SNDHWM=23, RCVHWM=24, RCVTIMEO=27, SNDTIMEO=28）
- [x] 3.3 添加 `SendRecvFlags` 枚举（DONTWAIT=1, SNDMORE=2）

## 4. 错误处理

- [ ] 4.1 创建 `src/zmq_error.cj`，定义 `ZmqError` 类（继承 Exception，包含 errno + message）
- [ ] 4.2 添加内部辅助函数 `checkResult(rc: Int32)`，rc == -1 时抛出 ZmqError

## 5. 上下文管理

- [ ] 5.1 创建 `src/zmq_context.cj`，定义 `ZmqContext` 类（实现 Resource 接口）
- [ ] 5.2 实现 `init()`，调用 zmq_ctx_new，失败时抛出 ZmqError
- [ ] 5.3 实现 `close()`，调用 zmq_ctx_term，带幂等保护（null handle 检查）
- [ ] 5.4 实现 `isClosed()`，检查 handle 是否为 null
- [ ] 5.5 实现 `socket(type_: SocketType): ZmqSocket` 方法

## 6. Socket 操作

- [ ] 6.1 创建 `src/zmq_socket.cj`，定义 `ZmqSocket` 类（实现 Resource 接口）
- [ ] 6.2 实现 `close()`，调用 zmq_close，带幂等保护
- [ ] 6.3 实现 `bind(addr: String)`，含 CString 转换和错误检查
- [ ] 6.4 实现 `connect(addr: String)`，含 CString 转换和错误检查
- [ ] 6.5 实现 `send(data: Array<UInt8>)`，含 CPointer 缓冲区转换
- [ ] 6.6 实现 `recv(): Array<UInt8>`，含缓冲区分配和数据拷贝
- [ ] 6.7 实现 `setSubscribe(topic: String)`，用于 SUB Socket（通过 zmq_setsockopt）
- [ ] 6.8 创建 `src/zmq_common.cj`，包含内部 String↔CString 转换工具函数

## 7. 通信模式测试

- [ ] 7.1 编写 REQ/REP 测试：服务端 bind → recv → send 回复，客户端 connect → send → recv 回复
- [ ] 7.2 编写 PUB/SUB 测试：发布者 bind → 发布，订阅者 connect → subscribe → recv（带主题过滤）
- [ ] 7.3 编写 PUSH/PULL 测试：推送者 connect → send，拉取者 bind → recv
- [ ] 7.4 验证所有测试在当前平台通过

## 8. 文档

- [ ] 8.1 编写 README，包含项目简介、构建说明、平台前置条件（cmake、C 编译器）
- [ ] 8.2 在 README 中添加 REQ/REP 快速入门示例代码
- [ ] 8.3 在 README 中添加 API 概览（ZmqContext、ZmqSocket、SocketType、ZmqError）
