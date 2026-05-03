## 背景

zmq4cj 通过 FFI 封装 libzmq。当前 `ZmqSocket` 的 `send()`/`recv()` 实现每次调用都通过 `LibC.malloc` 在堆上分配 `ZmqMsg` 结构体（64 字节），操作结束后再释放。在 C 语言中，`zmq_msg_t` 始终是栈分配的。此外，数据在仓颉 `Array<UInt8>` 和 C 指针之间通过 while 循环逐字节拷贝，而非使用 `memcpy`。`hasReceiveMore()` 方法每次调用都堆分配两个小临时指针。

基准测试结果（Linux ARM64）：
- inproc 64B：550K msg/s（原生 C：10-30M msg/s）
- inproc 64KB：带宽约 40 MB/s（原生 C：500MB-2GB/s）

## 目标 / 非目标

**目标：**
- 消除 `send()` 和 `recv()` 中每条消息的 ZmqMsg 堆分配
- 用 `memcpy` 替换逐字节拷贝，实现 O(n) 批量传输
- 消除 `hasReceiveMore()` 中每次调用的堆分配
- 保持完全相同的公共 API 和行为

**非目标：**
- 零拷贝发送 API（`zmq_msg_init_data` + 自定义析构器）— 未来工作
- 线程安全的 Socket 操作 — 不在范围内
- 修改 `bind()`/`connect()` 的字符串分配 — 影响极小，不值得增加复杂度

## 设计决策

### 1. 使用 `@C struct` 值栈分配 ZmqMsg

**决策**：将 `ZmqMsg` 声明为局部变量（栈分配的 `@C struct`），替代 `LibC.malloc<ZmqMsg>`。

**理由**：`ZmqMsg` 仅 64 字节，轻松放入栈帧。仓颉的 `@C struct` 内存布局与 C 结构体完全一致。取 `&msg` 可得到适用于 FFI 调用的 `CPointer<ZmqMsg>`。这消除了每条消息 2 次堆操作（malloc + free）。

**备选方案**：对象池分配 — 对 64 字节固定大小结构体来说不必要地复杂。

### 2. 添加 `memcpy` FFI 声明并用于批量拷贝

**决策**：在 `zmq_ffi.cj` 中添加 `foreign func memcpy(dest: CPointer<Unit>, src: CPointer<Unit>, n: UIntNative): CPointer<Unit>`。用基于 `memcpy` 的实现替换 `copyArrayToCPointer` 和 `copyCPointerToArray`。

**理由**：逐字节循环有 O(n) 次单独的指针操作。`memcpy` 在 libc 中经过高度优化（SIMD、字对齐）。对于 64KB 消息，这可能意味着从约 40 MB/s 提升到约 1 GB/s。

**实现细节**：需要验证仓颉 `Array<UInt8>` 的内存布局是否连续。如果不保证连续，则 `Array → CPointer` 方向保留循环，仅优化 `CPointer → Array` 方向（因为 `zmq_msg_data` 返回的是连续 C 缓冲区）。

### 3. 在 `hasReceiveMore()` 中使用栈变量

**决策**：使用局部 `Int32` 和 `UIntNative` 变量配合 `CPointer<T>(&var)`，替代 `LibC.malloc` + `LibC.free`。

**理由**：为 4+8 字节的值每次调用分配两次堆内存纯属浪费。栈变量的分配成本为零。

## 风险与权衡

- **[Array 连续性]** 仓颉 `Array<T>` 的内部布局可能不是连续的 C 兼容缓冲区 → **缓解**：双向测试；如果不连续，仅优化 `CPointer → Array` 方向，`Array → CPointer` 方向保留循环。
- **[栈 ZmqMsg 生命周期]** 必须确保 `ZmqMsg` 引用不会逃逸出函数 → **缓解**：ZmqMsg 仅在函数体内使用，通过指针传给 FFI 调用，不会被存储。
