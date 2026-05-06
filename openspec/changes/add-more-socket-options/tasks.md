## 1. SocketOption 枚举扩展

- [ ] 1.1 在 `SocketOption` 枚举中新增 24 个成员及对应 value 属性
- [ ] 1.2 新增 `setUnsubscribe(topic: String)` 便捷方法

## 2. 新增通用选项读写方法

- [ ] 2.1 在 `ZmqSocket` 中新增 `setInt64Option`/`getInt64Option` 方法
- [ ] 2.2 在 `ZmqSocket` 中新增 `setUInt64Option`/`getUInt64Option` 方法
- [ ] 2.3 在 `ZmqSocket` 中新增 `setBinaryOption`/`getBinaryOption` 方法

## 3. 测试

- [ ] 3.1 新增 Int32 选项测试（设置和读取 RECONNECT_IVL、BACKLOG 等）
- [ ] 3.2 新增 Int64 选项测试（MAXMSGSIZE）
- [ ] 3.3 新增 UInt64 选项测试（AFFINITY）
- [ ] 3.4 新增 binary 选项测试（ROUTING_ID）
- [ ] 3.5 新增 setUnsubscribe 测试
- [ ] 3.6 运行 `cjpm test` 确认全部通过
