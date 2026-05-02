## 1. FFI 层扩展

- [x] 1.1 在 `src/zmq_ffi.cj` 中新增 `zmq_msg_init_size(msg: CPointer<ZmqMsg>, size: UIntNative): Int32` 声明
- [x] 1.2 在 `src/zmq_ffi.cj` 中新增 `zmq_msg_send(msg: CPointer<ZmqMsg>, s: CPointer<Unit>, flags: Int32): Int32` 声明

## 2. 枚举扩展

- [x] 2.1 在 `src/zmq_types.cj` 的 `SocketOption` 枚举中新增 `RCVMORE`（值为 13）

## 3. Socket send 迁移与 flags 支持

- [x] 3.1 将 `ZmqSocket.send(data: Array<UInt8>)` 内部从 `zmq_send` 迁移到 `zmq_msg_init_size` + copy + `zmq_msg_send` + `zmq_msg_close`（保持签名不变）
- [x] 3.2 新增 `ZmqSocket.send(data: Array<UInt8>, flags: Int32)` 重载，支持传入 flags（SNDMORE、DONTWAIT）

## 4. Socket recv flags 支持

- [x] 4.1 新增 `ZmqSocket.recv(flags: Int32): Array<UInt8>` 重载，支持传入 flags（DONTWAIT）
- [x] 4.2 将现有 `recv(): Array<UInt8>` 改为调用 `recv(0)`

## 5. hasReceiveMore 方法

- [x] 5.1 实现 `ZmqSocket.hasReceiveMore(): Bool`，内部调用 `zmq_getsockopt` 查询 `ZMQ_RCVMORE`（SocketOption.RCVMORE.value = 13）

## 6. Multipart 便捷方法

- [x] 6.1 实现 `ZmqSocket.sendMultipart(frames: Array<Array<UInt8>>)`：遍历 frames，前 N-1 帧调用 `send(frame, SendRecvFlags.SNDMORE.value)`，最后一帧调用 `send(frame, 0)`
- [x] 6.2 实现 `ZmqSocket.recvMultipart(): Array<Array<UInt8>>`：先 `recv(0)` 收第一帧，然后 `while (hasReceiveMore())` 循环收后续帧，收集为 Array 返回

## 7. 测试

- [x] 7.1 编写多帧收发测试：PUSH 端 `sendMultipart([header, payload])`，PULL 端 `recvMultipart()` 验证收到 2 帧
- [x] 7.2 编写 ROUTER/DEALER 多帧测试：验证 identity frame + body frame 的多帧模式
- [x] 7.3 编写 hasReceiveMore 测试：发送多帧消息，验证接收端 RCVMORE 状态变化
- [x] 7.4 验证所有已有测试仍然通过（向后兼容）
