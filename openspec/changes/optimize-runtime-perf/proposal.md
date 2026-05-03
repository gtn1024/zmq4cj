## 动机

基准测试显示 zmq4cj 在小消息场景比原生 C ZeroMQ 慢 20-50 倍，大消息场景慢 10-40 倍。主要瓶颈有三个：每次消息收发都堆分配 ZmqMsg（应该栈分配）、逐字节数据拷贝（应该用 memcpy）、`hasReceiveMore()` 中不必要的堆分配。这些都是直截了当的优化，可以在不改变 API 的情况下获得数量级的性能提升。

## 变更内容

- 将 `send()` 和 `recv()` 中的堆分配 `ZmqMsg` 改为栈分配
- 将逐字节拷贝的 `copyArrayToCPointer` / `copyCPointerToArray` 替换为基于 `memcpy` 的批量拷贝
- 将 `hasReceiveMore()` 中的堆分配 `morePtr` / `sizePtr` 改为栈变量
- 在 `zmq_ffi.cj` 中添加 `memcpy` FFI 声明

## 能力

### 新增能力

- `fast-memory-copy`: 通过 FFI `memcpy` 实现批量内存拷贝工具，替换 `zmq_common.cj` 中的逐字节循环

### 修改能力

- `socket-operations`: 优化 `send()`、`recv()` 和 `hasReceiveMore()`，消除不必要的堆分配并使用批量内存拷贝

## 影响范围

- `src/zmq_ffi.cj`: 添加 `foreign func memcpy` 声明
- `src/zmq_common.cj`: 用 `memcpy` 版本替换 `copyArrayToCPointer` 和 `copyCPointerToArray` 的实现
- `src/zmq_socket.cj`: 栈分配 `ZmqMsg`，栈分配 `hasReceiveMore()` 中的选项缓冲区
- 无公共 API 变更 — 所有优化均为内部实现细节
- 现有测试应保持通过（行为完全一致，只是更快）
