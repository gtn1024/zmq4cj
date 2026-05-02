## 为什么

仓颉（Cangjie）语言目前没有 ZeroMQ 绑定库。ZeroMQ 是高性能分布式消息传递的事实标准库，被广泛用于微服务通信、金融系统和物联网场景。通过 FFI 封装 libzmq，为仓颉生态填补消息传递基础设施的空白。

## 变更内容

- 新建仓颉包 `zmq4cj`，通过 `foreign` FFI 封装 libzmq C 库的核心 API
- 提供仓颉惯用风格的安全 API（Resource 自动管理、异常替代 C 错误码、无 unsafe 暴露）
- 支持核心 Socket 类型：REQ/REP、PUB/SUB、PUSH/PULL、DEALER/ROUTER、PAIR
- 通过 `build.cj` 构建脚本从 libzmq 源码自动编译静态库（git submodule）
- 支持 macOS (x86_64 + ARM64)、Linux (x86_64 + ARM64)、Windows (x86_64)
- 同步 API 优先，MVP 阶段聚焦核心消息收发

## 能力

### 新增能力
- `ffi-bindings`：libzmq C 函数的 foreign FFI 声明层，包含所有核心函数的类型映射
- `context-management`：ZMQ 上下文生命周期管理（ZmqContext 类 + Resource 接口）
- `socket-operations`：Socket 创建、绑定、连接、收发、关闭（ZmqSocket 类 + Resource 接口）
- `error-handling`：ZMQ 错误处理（ZmqError 异常类，封装 zmq_errno/zmq_strerror）
- `build-system`：构建系统（build.cj + libzmq submodule + cjpm.toml FFI 配置）
- `socket-patterns`：核心通信模式验证（REQ/REP、PUB/SUB、PUSH/PULL 示例与测试）

### 修改能力
（无已有能力需修改）

## 影响

- **新增依赖**：libzmq 源码作为 git submodule（`vendor/libzmq/`）
- **构建依赖**：用户需安装 cmake 和 C 编译器（gcc/clang/MinGW）
- **cjpm.toml**：配置 `[ffi.c]` 和 `[target.*.ffi.c]` 静态链接选项
- **build.cj**：新增构建脚本，pre-build 钩子编译 libzmq 静态库
- **仓颉中心仓库**：发布源码包，用户本地编译含 native library
