# zmq4cj

ZeroMQ (libzmq) bindings for the Cangjie (仓颉) programming language.

## Prerequisites

- Cangjie toolchain >= 1.1.0
- CMake >= 3.15
- C compiler (gcc / clang / MinGW)

## Build

```bash
git clone --recursive https://github.com/gtn1024/zmq4cj.git
cd zmq4cj
cjpm build
```

On first build, `build.cj` automatically compiles libzmq from source (git submodule) into a static library. Subsequent builds reuse the cached artifact in `vendor/build/`.

To run tests:

```bash
cjpm test
```

## Quick Start: REQ/REP

```cangjie
package zmq4cj_demo

import zmq4cj.*

main() {
    let ctx = ZmqContext()
    let rep = ctx.socket(SocketType.REP)
    let req = ctx.socket(SocketType.REQ)

    rep.bind("tcp://*:5555")
    req.connect("tcp://localhost:5555")

    req.send("Hello".toArray())
    let msg = rep.recv()
    rep.send("World".toArray())
    let reply = req.recv()

    println("Received: ${String.fromUtf8(reply)}")

    req.close()
    rep.close()
    ctx.close()
}
```

## API Overview

### ZmqContext

Manages the ZMQ context lifecycle. Implements `Resource` for `try-with-resources`.

| Method | Description |
|--------|-------------|
| `init()` | Creates a new ZMQ context |
| `socket(type_: SocketType): ZmqSocket` | Creates a socket of the given type |
| `close()` | Terminates the context (idempotent) |
| `isClosed(): Bool` | Checks if the context is closed |

### ZmqSocket

Represents a ZMQ socket. Implements `Resource` for `try-with-resources`.

| Method | Description |
|--------|-------------|
| `bind(addr: String)` | Binds to an address (e.g. `"tcp://*:5555"`) |
| `connect(addr: String)` | Connects to an address |
| `send(data: Array<UInt8>)` | Sends binary data |
| `recv(): Array<UInt8>` | Receives binary data (blocking) |
| `setSubscribe(topic: String)` | Sets subscription filter for SUB sockets |
| `close()` | Closes the socket (idempotent) |
| `isClosed(): Bool` | Checks if the socket is closed |

### SocketType

| Value | Constant | Description |
|-------|----------|-------------|
| 0 | `PAIR` | Bidirectional pair |
| 1 | `PUB` | Publisher |
| 2 | `SUB` | Subscriber |
| 3 | `REQ` | Request |
| 4 | `REP` | Reply |
| 5 | `DEALER` | Dealer |
| 6 | `ROUTER` | Router |
| 7 | `PULL` | Pull |
| 8 | `PUSH` | Push |

### ZmqError

Exception class thrown on all ZMQ errors.

| Property | Description |
|----------|-------------|
| `errno: Int32` | ZMQ error code |
| `message: String` | Error description from `zmq_strerror` |
