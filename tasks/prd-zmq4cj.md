# PRD: zmq4cj — 仓颉语言 ZeroMQ 绑定库

## Introduction

为仓颉（Cangjie）编程语言提供 ZeroMQ (ZMQ) 的绑定库，通过 FFI 封装 libzmq C 库，提供仓颉惯用风格的安全 API。项目采用 MVP 先行、迭代扩展的策略，先实现核心消息收发功能，后续逐步支持异步、安全层和高级特性。

## Goals

- 通过仓颉 `foreign` FFI 封装 libzmq 的核心 C API
- 提供仓颉惯用风格的 API（Resource 自动管理生命周期、异常替代 C 错误码）
- 支持核心 Socket 类型：REQ/REP、PUB/SUB、PUSH/PULL、DEALER/ROUTER、PAIR
- 支持 macOS (x86_64 + ARM64)、Linux (x86_64 + ARM64)、Windows (x86_64)
- 静态链接 libzmq，用户无需额外安装依赖
- 同步 API 优先，后续迭代增加异步支持

## User Stories

### US-001: 项目脚手架与构建系统
**Description:** 作为开发者，我需要搭建项目结构并配置构建系统，使得项目可以正确编译和链接 libzmq。

**Acceptance Criteria:**
- [ ] libzmq 作为 git submodule 引入 `vendor/libzmq/`（源码，非预编译）
- [ ] `build.cj` 构建脚本在 `pre-build` 钩子中从源码编译 libzmq 静态库（cmake + make/MinGW）
- [ ] 编译输出到 `vendor/build/${platform}/`，`.gitignore` 忽略编译产物
- [ ] `cjpm.toml` 配置 `[target.*.ffi.c]` 指向各平台编译输出的库路径
- [ ] 用户执行 `git clone --recursive && cjpm build` 即可一键编译（含 libzmq）
- [ ] 全程源码编译，无预编译二进制依赖

### US-002: FFI 声明层
**Description:** 作为开发者，我需要声明 libzmq 的 C 函数，使得仓颉代码可以调用 libzmq。

**Acceptance Criteria:**
- [ ] 声明上下文管理函数：`zmq_ctx_new`, `zmq_ctx_term`, `zmq_ctx_set`, `zmq_ctx_get`
- [ ] 声明 Socket 管理函数：`zmq_socket`, `zmq_close`, `zmq_setsockopt`, `zmq_getsockopt`
- [ ] 声明连接函数：`zmq_bind`, `zmq_connect`, `zmq_unbind`, `zmq_disconnect`
- [ ] 声明消息收发函数：`zmq_send`, `zmq_recv`
- [ ] 声明错误处理函数：`zmq_errno`, `zmq_strerror`
- [ ] 所有 `foreign` 声明的类型映射正确（void* → CPointer<Unit>, size_t → UIntNative 等）
- [ ] 通过 `cjpm build` 编译通过

### US-003: SocketType 枚举与常量
**Description:** 作为库用户，我需要使用仓颉枚举来指定 Socket 类型，而不是记忆 C 的整数常量。

**Acceptance Criteria:**
- [ ] 定义 `SocketType` 枚举：PAIR(0), PUB(1), SUB(2), REQ(3), REP(4), DEALER(5), ROUTER(6), PULL(7), PUSH(8)
- [ ] 定义 `SocketOption` 枚举：SUBSCRIBE(6), UNSUBSCRIBE(7), LINGER(17), SNDHWM(23), RCVHWM(24), RCVTIMEO(27), SNDTIMEO(28) 等
- [ ] 定义 `SendRecvFlags`：DONTWAIT(1), SNDMORE(2)
- [ ] 编译通过

### US-004: ZmqContext 上下文管理
**Description:** 作为库用户，我需要创建和销毁 ZMQ 上下文，这是使用 ZMQ 的第一步。

**Acceptance Criteria:**
- [ ] `ZmqContext` 类封装 `zmq_ctx_new` / `zmq_ctx_term`
- [ ] `init()` 创建上下文，失败时抛出异常
- [ ] `terminate()` 销毁上下文
- [ ] `socket(type_: SocketType)` 方法创建 `ZmqSocket` 实例
- [ ] 实现 `Resource` 接口（`isClosed()` + `close()`），支持 `try (ctx = ZmqContext()) {}` 自动释放
- [ ] 编译通过

### US-005: ZmqSocket 基本操作
**Description:** 作为库用户，我需要通过 Socket 进行 bind、connect、send、recv 操作。

**Acceptance Criteria:**
- [ ] `bind(addr: String)` 绑定地址，失败抛出异常
- [ ] `connect(addr: String)` 连接地址，失败抛出异常
- [ ] `send(data: Array<UInt8>)` 发送二进制数据，失败抛出异常
- [ ] `recv(): Array<UInt8>` 接收二进制数据，失败抛出异常
- [ ] `close()` 关闭 Socket
- [ ] 所有错误通过 `ZmqError` 异常抛出，包含 errno 和错误描述
- [ ] 编译通过

### US-006: 错误处理
**Description:** 作为库用户，我希望 ZMQ 错误以仓颉异常的形式抛出，包含清晰的错误信息。

**Acceptance Criteria:**
- [ ] 定义 `ZmqError` 异常类，包含 errno 和 message
- [ ] `ZmqError` 的 message 通过 `zmq_strerror` 获取
- [ ] 所有可能失败的 FFI 调用都检查返回值并在失败时抛出 `ZmqError`
- [ ] 编译通过

### US-007: REQ/REP 模式示例与测试
**Description:** 作为库用户，我需要一个可运行的示例来验证 REQ/REP（请求-应答）模式正常工作。

**Acceptance Criteria:**
- [ ] 编写 REQ/REP 示例代码：服务端 bind → recv → send，客户端 connect → send → recv
- [ ] 示例可以成功运行并完成一次请求-应答
- [ ] 编写测试用例验证 REQ/REP 消息收发正确性
- [ ] 编译通过

### US-008: PUB/SUB 模式示例与测试
**Description:** 作为库用户，我需要验证 PUB/SUB（发布-订阅）模式正常工作。

**Acceptance Criteria:**
- [ ] 支持 SUB Socket 设置订阅主题（ZMQ_SUBSCRIBE socket option）
- [ ] 编写 PUB/SUB 示例代码
- [ ] 编写测试用例验证 PUB/SUB 消息收发正确性
- [ ] 编译通过

### US-009: PUSH/PULL 模式示例与测试
**Description:** 作为库用户，我需要验证 PUSH/PULL（推送-拉取）模式正常工作。

**Acceptance Criteria:**
- [ ] 编写 PUSH/PULL 示例代码
- [ ] 编写测试用例验证 PUSH/PULL 消息收发正确性
- [ ] 编译通过

### US-010: README 与使用文档
**Description:** 作为库用户，我需要清晰的文档来了解如何安装和使用 zmq4cj。

**Acceptance Criteria:**
- [ ] README 包含项目简介、安装步骤、构建方法
- [ ] README 包含各平台安装 libzmq 的说明
- [ ] README 包含 REQ/REP 快速入门示例代码
- [ ] README 包含 API 概览（ZmqContext、ZmqSocket、SocketType、ZmqError）

## Functional Requirements

- FR-1: 通过 `foreign` FFI 声明 libzmq 的核心 C 函数（上下文、Socket、连接、消息、错误）
- FR-2: 提供 `ZmqContext` 类管理 ZMQ 上下文生命周期，支持 Resource 接口
- FR-3: 提供 `ZmqSocket` 类封装 Socket 操作（bind, connect, send, recv, close）
- FR-4: 提供 `SocketType` 枚举映射所有核心 Socket 类型
- FR-5: 提供 `ZmqError` 异常类，通过 `zmq_errno` 和 `zmq_strerror` 提供错误信息
- FR-6: 所有 FFI 调用失败时抛出 `ZmqError` 而非返回错误码
- FR-7: 支持 String 与 CString 的自动转换（内部处理 mallocCString/free）
- FR-8: 静态链接 libzmq，编译产物无外部运行时依赖
- FR-9: 支持 macOS (x86_64, ARM64)、Linux (x86_64, ARM64)、Windows (x86_64)

## Non-Goals (Out of Scope)

- 不实现异步 API（后续迭代）
- 不实现 zmq_msg_t 多部分消息（后续迭代）
- 不实现安全认证（ZAP/CurveZMQ）
- 不实现代理（zmq_proxy）
- 不实现轮询（zmq_poll）
- 不实现 DRAFT 类型的 API
- 不实现纯仓颉重写 ZMTP 协议
- 不实现 ZMQ 4.0 以前版本的兼容

## Technical Considerations

- 仓颉 FFI 调用必须在 `unsafe` 块中，内部封装应对用户屏蔽 `unsafe`
- `void*` 映射为 `CPointer<Unit>`，需要时转换为具体类型的 `CPointer<T>`
- `size_t` 映射为 `UIntNative`，`int` 映射为 `Int32`
- String 传给 C 函数需通过 `LibC.mallocCString()` 转换，用完需 `LibC.free()`
- 仓颉线程调度与 C 线程局部变量不兼容，需注意避免在 ZMQ 回调中使用仓颉线程局部变量
- libzmq 静态链接通过 `build.cj` 的 `pre-build` 钩子自动编译 vendor/libzmq 源码
- cjpm.toml 中通过 `[ffi.c]` 配置 native library 路径，按平台用 `[target.*.ffi.c]` 区分
- Resource 接口需实现 `isClosed(): Bool` 和 `close(): Unit`，配合 `try (r = Resource()) {}` 自动释放
- 仓颉中心仓库只发布源码包，native library 不含在发布包中，由 `build.cj` 在用户本地编译

## Success Metrics

- MVP 阶段支持 REQ/REP、PUB/SUB、PUSH/PULL 三种核心模式
- 所有模式有可运行的示例和测试
- API 风格符合仓颉惯用法（Resource、异常、无 unsafe 暴露）
- 三个平台均可编译通过

## Resolved Questions

### Q1: Windows 平台的仓颉工具链和编译选项是否与 macOS/Linux 一致？

**已解决。** Windows 使用 `x86_64-windows-gnu` (LLVM-MinGW) 目标三元组，编译流程基本一致但有部分限制：
- 不支持 LTO、PGO、代码覆盖率插桩、rpath、build-id
- 输出文件后缀不同：`.exe`（可执行）、`.dll`（动态库）、`.obj`（目标文件）
- 仓颉 1.1.0 支持 Windows 全静态链接（`--static-std`）
- 条件编译使用 `@When[os == "Windows"]`，跨平台源码用 `specific` 关键字
- 支持从 Linux 交叉编译到 Windows（`x86_64-linux-gnu` → `x86_64-windows-gnu`）
- cjpm.toml 中按平台配置：`[target.x86_64-windows-gnu.ffi.c]`

### Q2: build.cj 中调用外部命令的跨平台方案？

**已解决。** 采用从源码编译方案（不使用预编译二进制，防止供应链投毒）：
- `vendor/libzmq/` 作为 git submodule 引入 libzmq 源码
- `build.cj` 的 `pre-build` 钩子检测平台，调用 cmake + make 从源码编译 libzmq 静态库
- 跨平台策略：
  - macOS/Linux：`build.cj` 中通过 FFI 调用 C 的 `system()` 执行 `cmake .. && make`
  - Windows：使用 MinGW（`x86_64-w64-mingw32`）编译，仓颉 Windows 工具链本身基于 LLVM-MinGW
- 编译输出到 `vendor/build/${platform}/` 目录
- `cjpm.toml` 中 `[target.*.ffi.c]` 指向各平台编译输出
- `build.cj` 通过 `Process.current.arguments[0]` 匹配 `"pre-build"` / `"post-build"` 钩子
- 添加 `.gitignore` 忽略 `vendor/build/` 编译产物

### Q3: zmq_setsockopt 和 ZMQ_SUBSCRIBE 的 CPointer 构造方式？

**已解决。** `zmq_setsockopt` 签名：
```c
int zmq_setsockopt(void *socket, int option_name, const void *option_value, size_t option_len);
```
仓颉声明：
```cangjie
foreign func zmq_setsockopt(socket: CPointer<Unit>, option_name: Int32,
                            option_value: CPointer<Unit>, option_len: UIntNative): Int32
```
ZMQ_SUBSCRIBE (值=6) 的 option_value 构造方式：
- String 主题：`LibC.mallocCString(topic)` 转为 `CString`，再取 `.getChars()` 得到 `CPointer<UInt8>`，转为 `CPointer<Unit>`
- 订阅全部：传 `CPointer<Unit>()`（null）+ `UIntNative(0)`
- 二进制前缀：分配 CPointer 缓冲区，逐字节写入
- ZMQ_LINGER (值=17)：传 `Int32` 变量的 `inout` 指针
