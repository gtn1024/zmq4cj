## 背景

当前 `send()` 实现路径（5 次 FFI 调用）：
1. `zmq_msg_init_size(CPointer<ZmqMsg>(inout msg), size)` — 栈分配 ZmqMsg 并初始化
2. `zmq_msg_data(msg)` — 获取数据指针
3. memcpy 拷贝用户数据到 msg buffer
4. `zmq_msg_send(msg, socket, flags)` — 发送
5. `zmq_msg_close(msg)` — 清理

优化后路径（3 次操作，1 次 FFI 调用）：
1. `acquireArrayRawData(data)` — 获取 Array 底层指针
2. `zmq_send(socket, pointer, size, flags)` — 单次 FFI 调用完成发送
3. `releaseArrayRawData(handle)` — 释放指针

## 目标 / 非目标

**目标：**
- 减少 send 路径的 FFI 调用次数从 5 次到 1 次
- 消除 ZmqMsg 栈分配（64 字节）和 init/close 开销
- 保持公共 API 签名完全不变

**非目标：**
- 优化 recv 路径（recv 必须先收 zmq_msg 才知道大小，无法用 zmq_recv 替代）
- 修改 multipart 发送逻辑（已委托到 send 方法，自动受益）
- 暴露零拷贝 API（未来工作）

## 设计决策

### 1. 使用 zmq_send 替代 zmq_msg_send

**决策**：`send(data, flags)` 改为 `acquireArrayRawData` → `zmq_send` → `releaseArrayRawData`。

**理由**：`zmq_send` 是 libzmq 的简化 API，内部自动完成 msg init/send/close。省去手动管理 ZmqMsg 的开销。结合 `acquireArrayRawData` 获取 Array 底层连续内存指针，可以直接传给 `zmq_send`，无需中间拷贝。

**实现细节**：
- zmq_send 的 buf 参数类型是 `CPointer<Unit>`，需要从 `CPointerHandle<UInt8>.pointer` 转换
- 空 Array（size == 0）需要特殊处理：传空指针和长度 0

### 2. multipart 发送自动受益

`sendMultipart` 循环调用 `send(data, flags)`，底层自动切换到 zmq_send，无需单独修改。

## 风险与权衡

- **[acquireArrayRawData 限制]** acquire 和 release 之间不能触发仓颉堆分配或 GC → **缓解**：zmq_send 是纯 C 调用，不会触发仓颉 GC
- **[zmq_send 内部拷贝]** zmq_send 会将用户数据拷贝到内部消息 buffer，和 zmq_msg_send 一样 → **不影响**：拷贝发生在 libzmq 内部，是不可避免的
