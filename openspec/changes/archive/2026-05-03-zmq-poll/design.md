## 背景

zmq_poll 是 libzmq 的事件轮询 API，允许同时监听多个 socket 的可读/可写/错误事件，并支持超时。其 C API 签名：

```c
int zmq_poll(zmq_pollitem_t *items, int nitems, long timeout);
```

其中 `zmq_pollitem_t` 包含：
- `void *socket`：ZMQ socket 指针（或 fd）
- `short events`：感兴趣的事件掩码（POLLIN=1, POLLOUT=2, POLLERR=4）
- `short revents`：返回的事件掩码

## 目标 / 非目标

**目标：**
- 提供 `PollItem` 类封装单个 poll 项
- 提供 `ZmqPoll.poll()` 静态方法
- 支持 POLLIN / POLLOUT / POLLERR 事件
- 支持超时（毫秒），-1 表示无限等待，0 表示立即返回

**非目标：**
- 不支持文件描述符轮询（仅支持 ZMQ socket）
- 不暴露 `zmq_poller`（libzmq 4.2+ 的新 API，thread-safe 版本，后续可考虑）
- 不支持边沿触发模式

## 设计决策

### 1. PollItem 用 @C struct 还是普通 class？

**决策**：使用普通 class + 手动 malloc `zmq_pollitem_t` 数组。

**理由**：`zmq_pollitem_t` 的布局在不同平台可能不同（socket 指针大小、对齐等）。用 `@C struct` 需要精确匹配 C 布局，容易出错。用 class 封装更安全，在 poll 调用时临时分配 C 数组即可。

### 2. PollItem 设计

```cangjie
public class PollItem {
    let socket: ZmqSocket
    let events: Int16
    var revents: Int16

    init(socket: ZmqSocket, events: Int16) {
        this.socket = socket
        this.events = events
        this.revents = 0
    }
}
```

`revents` 由 `ZmqPoll.poll()` 填充，用户通过 `item.revents` 检查。

### 3. zmq_pollitem_t 内存布局

在 64 位平台上，`zmq_pollitem_t` 大小为：
- `void *socket`: 8 字节
- `short events`: 2 字节
- `short revents`: 2 字节
- 可能的 padding: 4 字节（对齐到 void*）
- 总计: 16 字节

每个 PollItem 对应一个 `zmq_pollitem_t`。poll 时：
1. malloc `count * 16` 字节的 buffer
2. 遍历 PollItem 数组，填入 socket handle 和 events
3. 调用 `zmq_poll(buffer, count, timeout)`
4. 遍历 buffer，将 revents 写回 PollItem
5. free buffer

### 4. ZmqPoll 静态类

```cangjie
public class ZmqPoll {
    public static func poll(items: Array<PollItem>, timeout: Int64): Int32 {
        // 分配 zmq_pollitem_t 数组，填充，调用 zmq_poll，读回 revents
    }
}
```

返回值为就绪的 item 数量（或 0 表示超时，-1 表示错误）。

### 5. PollEvent 常量

```cangjie
public enum PollEvent {
    | POLLIN
    | POLLOUT
    | POLLERR

    public prop value: Int16 {
        get() { ... }  // 1, 2, 4
    }
}
```

### 6. FFI 声明

```cangjie
foreign func zmq_poll(items: CPointer<Unit>, nitems: Int32, timeout: Int64): Int32
```

## 风险与权衡

- **[zmq_pollitem_t 布局]** 依赖平台 ABI → **缓解**：通过 malloc + 手动填充字段，避免直接映射 struct
- **[fd 字段]** zmq_pollitem_t 支持 fd 轮询但本设计不支持 → **简化**：仅支持 ZMQ socket，fd 字段填 0
- **[超时精度]** zmq_poll 超时单位是毫秒 → **足够**：大多数场景够用
