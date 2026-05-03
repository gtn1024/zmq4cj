## 1. FFI 与工具层

- [x] 1.1 在 `src/zmq_ffi.cj` 中添加 `foreign func memcpy` 声明
- [x] 1.2 重写 `src/zmq_common.cj` 中的 `copyArrayToCPointer`，使用 `memcpy` 替代逐字节拷贝（已验证：Cangjie Array 不暴露连续内存，保持逐元素写入，memcpy 声明保留供未来零拷贝 API 使用）
- [x] 1.3 重写 `src/zmq_common.cj` 中的 `copyCPointerToArray`，使用 `memcpy` 替代逐字节拷贝（同上，保持逐元素实现）

## 2. Socket 操作优化

- [ ] 2.1 重写 `src/zmq_socket.cj` 中的 `send(data, flags)`：栈分配 `ZmqMsg`，使用 `memcpy` 拷贝数据，移除所有 `LibC.malloc`/`LibC.free`
- [ ] 2.2 重写 `src/zmq_socket.cj` 中的 `recv(flags)`：栈分配 `ZmqMsg`，使用 `memcpy` 拷贝数据，移除所有 `LibC.malloc`/`LibC.free`
- [ ] 2.3 重写 `src/zmq_socket.cj` 中的 `hasReceiveMore()`：使用栈变量替代 `LibC.malloc`/`LibC.free` 分配 `morePtr` 和 `sizePtr`

## 3. 验证

- [ ] 3.1 运行 `cjpm build` 和 `cjpm test`，确认全部 15 个测试通过
- [ ] 3.2 运行 benchmark 并与基线对比（预期大消息带宽有显著提升）
