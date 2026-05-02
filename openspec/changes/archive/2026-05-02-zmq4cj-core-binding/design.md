## 背景

仓颉（Cangjie）是华为推出的编程语言，提供 `foreign` FFI 机制直接调用 C 函数，无需手写桥接代码。本项目为仓颉语言封装 ZeroMQ（libzmq）C 库，提供消息传递基础设施。

当前状态：
- 仓颉工具链 v1.1.0 已安装在 macOS (aarch64)
- libzmq 是成熟的 C 库，提供稳定的 ABI（v4.3.x）
- 仓颉 FFI 支持 `foreign func` 声明、`CPointer<T>` 类型、`unsafe` 块
- cjpm 支持构建脚本（`build.cj`）和 `[ffi.c]` 配置

## 目标 / 非目标

**目标：**
- 提供 1:1 封装 libzmq 核心函数的 FFI 声明层
- 提供仓颉惯用的安全 API（Resource 自动释放、异常替代错误码）
- 支持 5 种核心 Socket 类型（REQ/REP, PUB/SUB, PUSH/PULL, DEALER/ROUTER, PAIR）
- 从 libzmq 源码自动编译静态库，防止供应链投毒
- 跨三平台（macOS/Linux/Windows）编译

**非目标：**
- 不实现异步 API（后续迭代）
- 不实现 zmq_msg_t 多部分消息
- 不实现安全认证（ZAP/CurveZMQ）
- 不实现代理和轮询
- 不实现 ZMTP 协议的纯仓颉重写

## 决策

### D1：源码编译而非预编译二进制

**选择**：git submodule 引入 libzmq 源码，`build.cj` pre-build 钩子本地编译

**替代方案**：
- 预编译 .a/.lib 提交到仓库 → 存在供应链投毒风险，仓库膨胀
- 要求用户自行安装 libzmq → 增加用户负担，版本不一致

**理由**：全程源码可审计，用户 `git clone --recursive && cjpm build` 一键完成，中心仓库发布源码包时也能自动编译。

### D2：三层架构

**选择**：FFI 声明层 → 内部安全封装层 → 公开 API 层

```
src/
├── zmq_ffi.cj        # foreign func 声明（1:1 映射 C 函数）
├── zmq_types.cj      # SocketType, SocketOption, SendRecvFlags 枚举
├── zmq_error.cj      # ZmqError 异常类
├── zmq_context.cj    # ZmqContext 类（Resource 接口）
├── zmq_socket.cj     # ZmqSocket 类（Resource 接口）
└── zmq_common.cj     # 内部工具函数（String/CString 转换等）
```

**理由**：分层隔离 unsafe 边界，FFI 层包含所有 `unsafe` 代码，API 层对用户完全透明。

### D3：Resource 接口管理生命周期

**选择**：ZmqContext 和 ZmqSocket 均实现 `Resource` 接口

```cangjie
class ZmqContext <: Resource {
    func isClosed(): Bool    // 检查 handle 是否为 null
    func close(): Unit       // 调用 zmq_ctx_term
}
class ZmqSocket <: Resource {
    func isClosed(): Bool    // 检查 handle 是否为 null
    func close(): Unit       // 调用 zmq_close
}
```

**理由**：仓颉的 `try (r = Resource()) {}` 语法保证资源释放，即使发生异常。比手动调用 close 更安全。

### D4：异常替代错误码

**选择**：所有 FFI 调用失败时抛出 `ZmqError` 异常

```cangjie
class ZmqError <: Exception {
    let errno: Int32
    let message: String  // 来自 zmq_strerror
}
```

**理由**：仓颉惯用异常处理，用户无需检查每个调用的返回值。C API 返回 -1 时通过 `zmq_errno()` 获取错误码。

### D5：类型映射约定

| C 类型 | 仓颉类型 | 说明 |
|--------|----------|------|
| `void*` | `CPointer<Unit>` | 通用指针，按需转换 |
| `void*` (ctx/socket) | `CPointer<Unit>` | 不透明句柄 |
| `size_t` | `UIntNative` | 平台相关无符号整数 |
| `int` | `Int32` | 32 位整数 |
| `const char*` | `CString` | C 字符串 |
| `char*` (输出) | `CPointer<UInt8>` | 输出缓冲区 |

### D6：构建系统设计

```
zmq4cj/
├── build.cj                          # pre-build 编译 libzmq
├── cjpm.toml                         # [ffi.c] + [target.*.ffi.c]
├── vendor/
│   └── libzmq/                       # git submodule
└── src/
```

`build.cj` 流程：
1. 检测当前平台（macOS/Linux/Windows）
2. 在 `vendor/build/${platform}/` 下执行 cmake + make
3. 输出 `libzmq.a`（或 Windows 下 `zmq.lib`）

## 风险 / 权衡

- **[build.cj 子进程调用]** → 仓颉标准库子进程 API 文档不完整，可能需要回退到 FFI `system()` 调用
- **[Windows MinGW 兼容性]** → 仓颉 Windows 工具链基于 LLVM-MinGW，libzmq 编译可能有兼容性问题 → 在 CI 中验证
- **[libzmq ABI 兼容性]** → 绑定特定版本（v4.3.5），源码锁定避免 ABI 变更
- **[仓颉 FFI 成熟度]** → 仓颉语言较新，FFI 边界情况可能遇到未文档化的行为 → 预留足够测试覆盖
- **[构建时间]** → 首次编译 libzmq 需要数分钟 → 通过 `vendor/build/` 缓存避免重复编译
