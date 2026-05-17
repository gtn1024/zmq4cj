# zmq

[![CI](https://github.com/gtn1024/zmq4cj/actions/workflows/ci.yml/badge.svg)](https://github.com/gtn1024/zmq4cj/actions/workflows/ci.yml)

ZeroMQ (libzmq v4.3.5) 仓颉语言绑定库。静态链接，运行时零外部依赖。

[English](README.md)

## 特性

- **安全 API**：`Resource` 接口自动管理生命周期，异常替代错误码，不暴露 `unsafe`/`CPointer`
- **静态链接**：构建时从源码编译 libzmq，用户无需单独安装
- **核心模式**：REQ/REP、PUB/SUB、PUSH/PULL、DEALER/ROUTER、PAIR
- **内置代理**：`ZmqProxy.start()` / `ZmqProxy.startSteerable()` 消息转发
- **多部分消息**：`sendMultipart` / `recvMultipart`
- **跨平台**：Linux（x86_64 + ARM64）、macOS（x86_64 + ARM64）— 暂不支持 Windows
- **线程安全上下文**：`ZmqContext.close()` 和 `socket()` 由 `Mutex` + `AtomicBool` 保护

## 环境要求

- 仓颉工具链 >= 1.1.0
- CMake >= 3.15
- C 编译器（gcc / clang）

## 安装

### 从中心仓库

在 `cjpm.toml` 中添加依赖：

```toml
[dependencies]
  zmq = "0.2.0"
```

> **注意：** libzmq 是 C++ 库，你还需要根据平台添加 C++ 运行时链接选项：
>
> ```toml
> [target.x86_64-unknown-linux-gnu]
>   link-option = "-lstdc++ -lgcc_s"
> [target.aarch64-unknown-linux-gnu]
>   link-option = "-lstdc++ -lgcc_s"
> [target.x86_64-apple-darwin]
>   link-option = "-lc++"
> [target.aarch64-apple-darwin]
>   link-option = "-lc++"
> ```

然后使用 `cjpm build` 构建项目。构建过程中会自动下载 zmq 并从源码编译 libzmq。

> **重要提示：** 请勿单独使用 `cjpm update` — 它不会执行编译 libzmq 的预构建脚本。请直接使用 `cjpm build`，它会按正确顺序处理依赖解析、预构建和编译。

### 从源码构建

```bash
git clone --recursive https://github.com/gtn1024/zmq4cj.git
cd zmq4cj
cjpm build
```

首次构建时，`build.cj` 会自动从源码编译 libzmq 为静态库。后续构建复用缓存产物。

## 快速入门

### REQ/REP（请求-应答）

```cangjie
package zmq_demo

import zmq.*

main() {
    let ctx = ZmqContext()
    let rep = ctx.socket(SocketType.REP)
    let req = ctx.socket(SocketType.REQ)

    rep.bind("tcp://*:5555")
    req.connect("tcp://localhost:5555")

    spawn {
        let msg = rep.recv()
        rep.send("World".toArray())
    }

    req.send("Hello".toArray())
    let reply = req.recv()
    println("收到: ${String.fromUtf8(reply)}")

    req.close()
    rep.close()
    ctx.close()
}
```

### PUB/SUB（发布-订阅）

```cangjie
let pub = ctx.socket(SocketType.PUB)
let sub = ctx.socket(SocketType.SUB)

pub.bind("tcp://*:5556")
sub.connect("tcp://localhost:5556")
sub.setSubscribe("weather.")

pub.send("weather.temp=25".toArray())
let msg = sub.recv()
```

### PUSH/PULL（管道）

```cangjie
let push = ctx.socket(SocketType.PUSH)
let pull = ctx.socket(SocketType.PULL)

push.bind("tcp://*:5557")
pull.connect("tcp://localhost:5557")

push.send("task-1".toArray())
let task = pull.recv()
```

### 多部分消息

```cangjie
let push = ctx.socket(SocketType.PUSH)
let pull = ctx.socket(SocketType.PULL)

push.bind("inproc://test")
pull.connect("inproc://test")

push.sendMultipart([
    "header".toArray(),
    "payload".toArray()
])

let frames = pull.recvMultipart()
println(frames.size.toString())
```

### try-with-resources 自动资源管理

```cangjie
try (ctx = ZmqContext()) {
    try (sock = ctx.socket(SocketType.REQ)) {
        sock.connect("tcp://localhost:5555")
        sock.send("Hello".toArray())
        let reply = sock.recv()
    }
}
```

### Socket 选项

```cangjie
let sock = ctx.socket(SocketType.REQ)

// 设置接收超时为 5 秒
sock.setIntOption(SocketOption.RCVTIMEO, 5000)

// 设置 LINGER 为 0（关闭时不等待）
sock.setIntOption(SocketOption.LINGER, 0)

// 读取当前值
let linger = sock.getIntOption(SocketOption.LINGER)

// 取消订阅
let sub = ctx.socket(SocketType.SUB)
sub.setStringOption(SocketOption.UNSUBSCRIBE, "weather.")
```

### 轮询（zmq_poll）

```cangjie
import std.collection.ArrayList

let push = ctx.socket(SocketType.PUSH)
let pull = ctx.socket(SocketType.PULL)
push.bind("tcp://*:5555")
pull.connect("tcp://localhost:5555")

push.send("event".toArray())

let list = ArrayList<PollItem>()
list.add(PollItem(pull, PollEvent.POLLIN.value))
let ready = ZmqPoll.poll(list.toArray(), 1000)  // 1 秒超时
if (ready > 0 && (list[0].revents & PollEvent.POLLIN.value) != Int16(0)) {
    let msg = pull.recv()
}
```

### 代理（zmq_proxy）

```cangjie
let frontend = ctx.socket(SocketType.PULL)
let backend = ctx.socket(SocketType.PUSH)
let control = ctx.socket(SocketType.PAIR)

frontend.bind("tcp://*:5555")
backend.bind("tcp://*:5556")
control.bind("inproc://control")

// 阻塞当前线程，在 spawn 中运行
spawn {
    ZmqProxy.startSteerable(frontend, backend, control)
    frontend.close()
    backend.close()
    control.close()
}

// 通过 control socket 终止代理
let client = ctx.socket(SocketType.PAIR)
client.connect("inproc://control")
client.send("TERMINATE".toArray())
```

## API 参考

### ZmqContext

管理 ZMQ 上下文生命周期。实现 `Resource` 接口，支持 `try-with-resources`。

| 方法 | 说明 |
|------|------|
| `init()` | 创建 ZMQ 上下文 |
| `socket(type_: SocketType): ZmqSocket` | 创建指定类型的 Socket |
| `close()` | 终止上下文（幂等、线程安全） |
| `isClosed(): Bool` | 检查上下文是否已关闭 |

### ZmqSocket

表示 ZMQ Socket。实现 `Resource` 接口，支持 `try-with-resources`。

| 方法 | 说明 |
|------|------|
| `bind(addr: String)` | 绑定地址（如 `"tcp://*:5555"`、`"inproc://test"`） |
| `connect(addr: String)` | 连接到地址 |
| `send(data: Array<UInt8>)` | 发送二进制数据（阻塞） |
| `send(data: Array<UInt8>, flags: Int32)` | 带标志发送（如 `SendRecvFlags.SNDMORE`） |
| `recv(): Array<UInt8>` | 接收二进制数据（阻塞） |
| `recv(flags: Int32): Array<UInt8>` | 带标志接收（如 `SendRecvFlags.DONTWAIT`） |
| `sendMultipart(frames: Array<Array<UInt8>>)` | 发送多部分消息 |
| `recvMultipart(): Array<Array<UInt8>>` | 接收多部分消息的所有帧 |
| `hasReceiveMore(): Bool` | 是否还有更多帧可接收 |
| `setSubscribe(topic: String)` | 设置 SUB Socket 的订阅主题 |
| `setIntOption(option, value: Int32)` | 设置整数类型的 Socket 选项（LINGER、RCVTIMEO、SNDHWM 等） |
| `getIntOption(option): Int32` | 读取整数类型的 Socket 选项 |
| `setStringOption(option, value: String)` | 设置字符串类型的 Socket 选项（SUBSCRIBE、UNSUBSCRIBE） |
| `close()` | 关闭 Socket（幂等、线程安全） |
| `isClosed(): Bool` | 检查 Socket 是否已关闭 |

### SocketType

| 值 | 常量 | 说明 |
|----|------|------|
| 0 | `PAIR` | 双向配对 |
| 1 | `PUB` | 发布者 |
| 2 | `SUB` | 订阅者 |
| 3 | `REQ` | 请求方 |
| 4 | `REP` | 应答方 |
| 5 | `DEALER` | Dealer（高级请求/应答模式） |
| 6 | `ROUTER` | Router（高级请求/应答模式） |
| 7 | `PULL` | 拉取（管道接收端） |
| 8 | `PUSH` | 推送（管道发送端） |
| 9 | `XPUB` | 扩展发布者（类似 PUB，可接收订阅消息） |
| 10 | `XSUB` | 扩展订阅者（类似 SUB，可发送订阅给 PUB） |
| 11 | `STREAM` | 流式 Socket（原始 TCP 收发） |

### SendRecvFlags

| 值 | 常量 | 说明 |
|----|------|------|
| 1 | `DONTWAIT` | 非阻塞发送/接收 |
| 2 | `SNDMORE` | 后续还有更多消息帧 |

### SocketOption

| 值 | 常量 | 说明 |
|----|------|------|
| 6 | `SUBSCRIBE` | 订阅主题（仅 SUB） |
| 7 | `UNSUBSCRIBE` | 取消订阅 |
| 13 | `RCVMORE` | 是否还有更多帧可接收 |
| 17 | `LINGER` | 关闭时的等待时间（毫秒） |
| 23 | `SNDHWM` | 发送高水位 |
| 24 | `RCVHWM` | 接收高水位 |
| 27 | `RCVTIMEO` | 接收超时（毫秒） |
| 28 | `SNDTIMEO` | 发送超时（毫秒） |

### ZmqProxy

提供内置 ZMQ 代理的静态类，用于在 Socket 之间转发消息。

| 方法 | 说明 |
|------|------|
| `start(frontend, backend, capture?)` | 启动阻塞代理。上下文终止时（ETERM）返回。 |
| `startSteerable(frontend, backend, capture?, control)` | 启动可控代理。向 control socket 发送 `"TERMINATE"` 可停止代理。 |

### ZmqError

所有 ZMQ 错误抛出的异常类。

| 属性 | 说明 |
|------|------|
| `errno: Int32` | ZMQ 错误码 |
| `message: String` | 来自 `zmq_strerror` 的错误描述 |

### PollItem

表示轮询操作中要监听的 socket。

| 属性 | 类型 | 说明 |
|------|------|------|
| `socket` | `ZmqSocket` | 要监听的 Socket |
| `events` | `Int16` | 事件掩码（`PollEvent` 值的组合） |
| `revents` | `Int16` | 返回的事件（由 `ZmqPoll.poll()` 填充） |

### ZmqPoll

提供轮询操作的静态类。

| 方法 | 说明 |
|------|------|
| `poll(items: Array<PollItem>, timeout: Int64): Int32` | 轮询多个 Socket。返回就绪的 item 数量。`timeout` 单位为毫秒（-1 = 无限等待，0 = 立即返回）。 |

### PollEvent

| 值 | 常量 | 说明 |
|----|------|------|
| 1 | `POLLIN` | Socket 可读 |
| 2 | `POLLOUT` | Socket 可写 |
| 4 | `POLLERR` | Socket 出错 |

## 线程安全

- **`ZmqContext.close()` 和 `socket()`** 是线程安全的 — 多线程可安全地并发创建 Socket 或关闭上下文。
- **`ZmqSocket.close()`** 是线程安全的（通过 `AtomicBool.compareAndSwap` 保证幂等）。
- **`ZmqSocket` 操作**（`send`/`recv`/`bind`/`connect`）**不是线程安全的** — 遵循"一个 Socket 一个线程"原则。

## 运行测试

```bash
cjpm test
```

## 运行基准测试

```bash
cd benchmark
cjpm run
```
