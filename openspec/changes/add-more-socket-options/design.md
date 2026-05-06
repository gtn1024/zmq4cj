## Context

`SocketOption` 枚举目前只有 8 个成员。`ZmqSocket` 提供 `setIntOption`/`getIntOption`（Int32）和 `setStringOption`（String）三种通用方法。但 libzmq 的部分选项使用 Int64、UInt64 或 binary（byte array）类型，现有方法无法覆盖。

## Goals / Non-Goals

**Goals:**

- `SocketOption` 枚举覆盖 libzmq 所有常用整数型选项
- 新增 Int64、UInt64、binary 通用读写方法，与现有 Int32/String 方法对称
- 新增 `setUnsubscribe` 便捷方法
- 测试覆盖新增方法

**Non-Goals:**

- 不封装所有 libzmq 选项（仅封装常用的 ~25 个）
- 不新增类型安全的逐选项方法（如 `setLinger(ms: Int32)`），保持通用 `setIntOption` 模式
- 不封装只写选项的特殊处理（SUBSCRIBE/UNSUBSCRIBE 已有便捷方法）

## Decisions

- **按类型分组添加方法**：新增 `setInt64Option`/`getInt64Option`、`setUInt64Option`/`getUInt64Option`、`setBinaryOption`/`getBinaryOption`，与现有 `setIntOption`/`getIntOption`/`setStringOption` 对称。
- **复用现有 checkResult**：所有新方法使用同一错误检查模式。
- **binary 选项用 `Array<UInt8>`**：Cangjie 中二进制数据用 `Array<UInt8>`，通过 `acquireArrayRawData` 获取指针传给 `zmq_setsockopt`/`zmq_getsockopt`。
- **IDENTITY（值 5）和 ROUTING_ID（值 80）**：两者功能类似，ROUTING_ID 是 ZMQ 4.2+ 新名。都封装为 binary 选项。

## Risks / Trade-offs

- **[UInt64 选项数量少]** → AFFINITY 是唯一 UInt64 选项。新增 `setUInt64Option` 方法虽只为一个选项服务，但保持 API 对称性和未来扩展性。
- **[binary 选项读取需预分配]** → `getBinaryOption` 需要先查询选项值大小再分配缓冲区，增加一次 FFI 调用。可接受。
