# zmq4cj

[![CI](https://github.com/gtn1024/zmq4cj/actions/workflows/ci.yml/badge.svg)](https://github.com/gtn1024/zmq4cj/actions/workflows/ci.yml)

ZeroMQ (libzmq v4.3.5) bindings for the Cangjie (仓颉) programming language. Static linking, zero external dependencies at runtime.

[中文文档](README-zh.md)

## Features

- **Safe API**: `Resource` interface for automatic cleanup, exceptions instead of error codes, no `unsafe`/`CPointer` exposed to users
- **Static linking**: libzmq is compiled from source during build — users don't need to install libzmq separately
- **Core patterns**: REQ/REP, PUB/SUB, PUSH/PULL, DEALER/ROUTER, PAIR
- **Multipart messages**: `sendMultipart` / `recvMultipart`
- **Cross-platform**: Linux (x86_64 + ARM64), macOS (x86_64 + ARM64)
- **Thread-safe context**: `ZmqContext.close()` and `socket()` are protected by `Mutex` + `AtomicBool`

## Prerequisites

- Cangjie toolchain >= 1.1.0
- CMake >= 3.15
- C compiler (gcc / clang)

## Installation

Add to your `cjpm.toml`:

```toml
[dependencies]
zmq4cj = { git = "https://github.com/gtn1024/zmq4cj.git" }
```

Or clone and build from source:

```bash
git clone --recursive https://github.com/gtn1024/zmq4cj.git
cd zmq4cj
cjpm build
```

On first build, `build.cj` automatically compiles libzmq from source (git submodule) into a static library. Subsequent builds reuse the cached artifact in `vendor/build/`.

## Quick Start

### REQ/REP (Request-Reply)

```cangjie
package zmq4cj_demo

import zmq4cj.*

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
    println("Received: ${String.fromUtf8(reply)}")

    req.close()
    rep.close()
    ctx.close()
}
```

### PUB/SUB (Publish-Subscribe)

```cangjie
let pub = ctx.socket(SocketType.PUB)
let sub = ctx.socket(SocketType.SUB)

pub.bind("tcp://*:5556")
sub.connect("tcp://localhost:5556")
sub.setSubscribe("weather.")

pub.send("weather.temp=25".toArray())
let msg = sub.recv()
```

### PUSH/PULL (Pipeline)

```cangjie
let push = ctx.socket(SocketType.PUSH)
let pull = ctx.socket(SocketType.PULL)

push.bind("tcp://*:5557")
pull.connect("tcp://localhost:5557")

push.send("task-1".toArray())
let task = pull.recv()
```

### Multipart Messages

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

### Resource Management with `try-with-resources`

```cangjie
try (ctx = ZmqContext()) {
    try (sock = ctx.socket(SocketType.REQ)) {
        sock.connect("tcp://localhost:5555")
        sock.send("Hello".toArray())
        let reply = sock.recv()
    }
}
```

### Socket Options

```cangjie
let sock = ctx.socket(SocketType.REQ)

// Set receive timeout to 5 seconds
sock.setIntOption(SocketOption.RCVTIMEO, 5000)

// Set linger to 0 (don't wait on close)
sock.setIntOption(SocketOption.LINGER, 0)

// Read current value
let linger = sock.getIntOption(SocketOption.LINGER)

// Unsubscribe from a topic
let sub = ctx.socket(SocketType.SUB)
sub.setStringOption(SocketOption.UNSUBSCRIBE, "weather.")
```

### Polling (zmq_poll)

```cangjie
import std.collection.ArrayList

let push = ctx.socket(SocketType.PUSH)
let pull = ctx.socket(SocketType.PULL)
push.bind("tcp://*:5555")
pull.connect("tcp://localhost:5555")

push.send("event".toArray())

let list = ArrayList<PollItem>()
list.add(PollItem(pull, PollEvent.POLLIN.value))
let ready = ZmqPoll.poll(list.toArray(), 1000)  // 1s timeout
if (ready > 0 && (list[0].revents & PollEvent.POLLIN.value) != Int16(0)) {
    let msg = pull.recv()
}
```

## API Reference

### ZmqContext

Manages the ZMQ context lifecycle. Implements `Resource` for `try-with-resources`.

| Method | Description |
|--------|-------------|
| `init()` | Creates a new ZMQ context |
| `socket(type_: SocketType): ZmqSocket` | Creates a socket of the given type |
| `close()` | Terminates the context (idempotent, thread-safe) |
| `isClosed(): Bool` | Checks if the context is closed |

### ZmqSocket

Represents a ZMQ socket. Implements `Resource` for `try-with-resources`.

| Method | Description |
|--------|-------------|
| `bind(addr: String)` | Binds to an address (e.g. `"tcp://*:5555"`, `"inproc://test"`) |
| `connect(addr: String)` | Connects to an address |
| `send(data: Array<UInt8>)` | Sends binary data (blocking) |
| `send(data: Array<UInt8>, flags: Int32)` | Sends with flags (e.g. `SendRecvFlags.SNDMORE`) |
| `recv(): Array<UInt8>` | Receives binary data (blocking) |
| `recv(flags: Int32): Array<UInt8>` | Receives with flags (e.g. `SendRecvFlags.DONTWAIT`) |
| `sendMultipart(frames: Array<Array<UInt8>>)` | Sends a multipart message |
| `recvMultipart(): Array<Array<UInt8>>` | Receives all frames of a multipart message |
| `hasReceiveMore(): Bool` | Whether more frames are available |
| `setSubscribe(topic: String)` | Sets subscription filter for SUB sockets |
| `setIntOption(option, value: Int32)` | Sets an integer socket option (LINGER, RCVTIMEO, SNDHWM, etc.) |
| `getIntOption(option): Int32` | Gets an integer socket option |
| `setStringOption(option, value: String)` | Sets a string socket option (SUBSCRIBE, UNSUBSCRIBE) |
| `close()` | Closes the socket (idempotent, thread-safe) |
| `isClosed(): Bool` | Checks if the socket is closed |

### SocketType

| Value | Constant | Description |
|-------|----------|-------------|
| 0 | `PAIR` | Bidirectional pair (exclusive pair of sockets) |
| 1 | `PUB` | Publisher (distributes messages to subscribers) |
| 2 | `SUB` | Subscriber (receives messages from publishers) |
| 3 | `REQ` | Request (sends requests, receives replies) |
| 4 | `REP` | Reply (receives requests, sends replies) |
| 5 | `DEALER` | Dealer (advanced request/reply pattern) |
| 6 | `ROUTER` | Router (advanced request/reply pattern) |
| 7 | `PULL` | Pull (receives messages from pipeline) |
| 8 | `PUSH` | Push (sends messages to pipeline) |

### SendRecvFlags

| Value | Constant | Description |
|-------|----------|-------------|
| 1 | `DONTWAIT` | Non-blocking send/recv |
| 2 | `SNDMORE` | More message frames follow |

### SocketOption

| Value | Constant | Description |
|-------|----------|-------------|
| 6 | `SUBSCRIBE` | Subscribe to topic (SUB only) |
| 7 | `UNSUBSCRIBE` | Unsubscribe from topic |
| 13 | `RCVMORE` | More message frames to receive |
| 17 | `LINGER` | Linger period for socket shutdown (ms) |
| 23 | `SNDHWM` | High water mark for outbound messages |
| 24 | `RCVHWM` | High water mark for inbound messages |
| 27 | `RCVTIMEO` | Receive timeout (ms) |
| 28 | `SNDTIMEO` | Send timeout (ms) |

### ZmqError

Exception class thrown on all ZMQ errors.

| Property | Description |
|----------|-------------|
| `errno: Int32` | ZMQ error code |
| `message: String` | Error description from `zmq_strerror` |

### PollItem

Represents a socket to monitor in a poll operation.

| Property | Type | Description |
|----------|------|-------------|
| `socket` | `ZmqSocket` | The socket to monitor |
| `events` | `Int16` | Event mask (combination of `PollEvent` values) |
| `revents` | `Int16` | Returned events (filled by `ZmqPoll.poll()`) |

### ZmqPoll

Static class providing the poll operation.

| Method | Description |
|--------|-------------|
| `poll(items: Array<PollItem>, timeout: Int64): Int32` | Polls multiple sockets. Returns number of ready items. `timeout` in ms (-1 = infinite, 0 = immediate). |

### PollEvent

| Value | Constant | Description |
|-------|----------|-------------|
| 1 | `POLLIN` | Socket is readable |
| 2 | `POLLOUT` | Socket is writable |
| 4 | `POLLERR` | Socket has error |

## Thread Safety

- **`ZmqContext.close()` and `socket()`** are thread-safe — multiple threads can safely create sockets or close the context concurrently.
- **`ZmqSocket.close()`** is thread-safe (idempotent via `AtomicBool.compareAndSwap`).
- **`ZmqSocket` operations** (`send`/`recv`/`bind`/`connect`) are **NOT thread-safe** — follow the "one socket per thread" principle.

## Running Tests

```bash
cjpm test
```

## Running Benchmarks

```bash
cd benchmark
cjpm run
```
