## 1. 实现

- [ ] 1.1 重写 `src/zmq_socket.cj` 中的 `send(data, flags)`：使用 `acquireArrayRawData` + `zmq_send` + `releaseArrayRawData` 替代 zmq_msg API，处理空 Array 和错误场景

## 2. 验证

- [ ] 2.1 运行 `cjpm build` 和 `cjpm test`，确认全部 18 个测试通过
- [ ] 2.2 运行 benchmark 并与基线对比
