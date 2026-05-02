## 背景

当前 zmq4cj 已实现单帧消息收发（Phase 1 MVP）。用户需要迁移 Python ZeroMQ 工作负载，其中 PULL 端使用 `recv_multipart()` 接收多帧消息（header + payload 分帧）。主流 ZeroMQ 绑定库（pyzmq、jeromq、czmq）均提供多帧消息支持。

pyzmq 和 jeromq 的设计共识：
- **多帧是用户空间抽象**：底层是单帧 send/recv + SNDMORE flag + RCVMORE socket option 的循环
- **分层设计**：先有底层 flags 支持，再在上层组合出 multipart 便捷方法
- 不引入额外的 Message 类型（如 jeromq 的 ZMsg/ZFrame），保持简单

当前库已有的基础设施：
- `ZmqMsg` 结构体（64 字节 @C struct）和 `zmq_msg_init`、`zmq_msg_recv`、`zmq_msg_close`、`zmq_msg_data`、`zmq_msg_size` FFI 声明
- `SendRecvFlags` 枚举（DONTWAIT=1, SNDMORE=2）已定义但未使用
- 现有 `send()` 使用 `zmq_send`，`recv()` 使用 `zmq_msg_recv`

## 目标 / 非目标

**目标：**
- 为 `send` / `recv` 增加 flags 参数支持（向后兼容现有无参调用）
- 新增 `hasReceiveMore()` 方法查询 RCVMORE
- 新增 `sendMultipart(frames)` / `recvMultipart()` 便捷方法
- 新增 `zmq_msg_send` FFI 声明
- 覆盖多帧收发的测试

**非目标：**
- 不引入 ZMsg/ZFrame 等高层消息类型
- 不实现 zero-copy 发送
- 不实现异步/非阻塞收发（DONTWAIT flag 声明但暂不重点测试）
- 不实现代理和轮询

## 决策

### D1：send/recv 使用 zmq_msg_t API

**选择**：所有收发操作统一使用 `zmq_msg_t` API（`zmq_msg_init` + `zmq_msg_send`/`zmq_msg_recv` + `zmq_msg_close`），替代当前 `send()` 使用的 `zmq_send`（需预分配固定缓冲区）

**替代方案**：
- 保持 `zmq_send` + `zmq_msg_recv` 混用 → 发送侧需要预分配缓冲区且有截断风险
- 全部使用 `zmq_send`/`zmq_recv` → `zmq_recv` 无法正确处理变长消息

**理由**：`zmq_msg_t` API 是 ZeroMQ 推荐的收发方式，自动管理缓冲区分配，避免截断问题。当前 `recv()` 已经使用 `zmq_msg_recv`，只需将 `send()` 也迁移到 `zmq_msg_send`。

### D2：send/recv flags 重载而非默认参数

**选择**：新增带 `flags: SendRecvFlags` 参数的重载方法，保留无参版本

```cangjie
send(data: Array<UInt8>)                    // 保留，flags = 0
send(data: Array<UInt8>, flags: Int32)      // 新增
recv(): Array<UInt8>                        // 保留，flags = 0
recv(flags: Int32): Array<UInt8>            // 新增
```

**理由**：仓颉不支持默认参数值。使用 `Int32` 而非 `SendRecvFlags` 枚举参数，因为 flags 可以是组合值（如 `DONTWAIT | SNDMORE`），枚举不便于位运算组合。

### D3：multipart 方法返回 Array<Array<UInt8>>

**选择**：`sendMultipart(frames: Array<Array<UInt8>>)` / `recvMultipart(): Array<Array<UInt8>>`

**替代方案**：
- 引入 `ZmqMessage` 类型 → 过度设计，当前阶段不需要
- 返回 `Iterator<Array<UInt8>>` → 仓颉迭代器生态不成熟

**理由**：对标 pyzmq 的 `send_multipart(msg_parts: list)` / `recv_multipart() -> list[bytes]`，简单直接。

### D4：hasReceiveMore 使用 zmq_getsockopt

**选择**：内部调用 `zmq_getsockopt` 查询 `ZMQ_RCVMORE`（值为 13），返回 `Bool`

**实现**：
```cangjie
public func hasReceiveMore(): Bool {
    var more: Int32 = 0
    unsafe {
        let morePtr = CPointer<Int32>(LibC.malloc<Int32>(count: 1))
        let sizePtr = LibC.malloc<UIntNative>(count: 1)
        (sizePtr + 0).write(UIntNative(4))
        zmq_getsockopt(handle, 13, CPointer<Unit>(morePtr), sizePtr)
        more = (morePtr + 0).read()
        LibC.free(morePtr)
        LibC.free(sizePtr)
    }
    more == 1
}
```

### D5：send 内部迁移到 zmq_msg_send

**当前**：`send()` 使用 `zmq_send(handle, buf, len, flags)`
**迁移后**：`send()` 使用 `zmq_msg_init_size` + copy + `zmq_msg_send(msg, handle, flags)` + `zmq_msg_close(msg)`

需要新增 FFI：`zmq_msg_init_size(msg, size)`

## 风险 / 权衡

- **[zmq_msg_init_size 兼容性]** → 需确认 libzmq 4.3.5 导出此符号，是标准 API 无风险
- **[send 方法签名变更]** → 保持原有无参签名，新增重载，完全向后兼容
- **[性能]** → zmq_msg_t API 有额外 init/close 开销，但这是 libzmq 推荐方式，开销可忽略
