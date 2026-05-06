package zmq_bench

import zmq.*
import std.time.*

let WARMUP_MSG_COUNT: Int64 = 1000
let BENCH_MSG_COUNT: Int64 = 100000

var portCounter: Int64 = 9000

func nextPort(): String {
    let p = portCounter.toString()
    portCounter++
    p
}

func makePayload(size: Int64): Array<UInt8> {
    Array<UInt8>(size, repeat: 65)
}

func makeAddr(transport: String, label: String): String {
    if (transport == "inproc") {
        "inproc://${label}"
    } else {
        "tcp://*:${nextPort()}"
    }
}

func connectAddr(transport: String, bindAddr: String): String {
    if (transport == "inproc") {
        bindAddr
    } else {
        bindAddr.replace("*", "127.0.0.1")
    }
}

func benchThroughput(label: String, msgSize: Int64, count: Int64, transport: String): Unit {
    let ctx = ZmqContext()
    let pull = ctx.socket(SocketType.PULL)
    let push = ctx.socket(SocketType.PUSH)

    let addr = makeAddr(transport, "thr-${msgSize}")
    pull.bind(addr)
    push.connect(connectAddr(transport, addr))

    let payload = makePayload(msgSize)

    let fut = spawn {
        var i: Int64 = 0
        while (i < WARMUP_MSG_COUNT + count) {
            pull.recv()
            i++
        }
        pull.close()
    }

    var i: Int64 = 0
    while (i < WARMUP_MSG_COUNT) {
        push.send(payload)
        i++
    }

    let start = DateTime.now()
    i = 0
    while (i < count) {
        push.send(payload)
        i++
    }
    let elapsedNs = (DateTime.now() - start).toNanoseconds()

    fut.get()
    push.close()
    ctx.close()

    let elapsedMs = Float64(elapsedNs) / 1_000_000.0
    let msgsPerSec = Float64(count) / (elapsedMs / 1000.0)
    let mbPerSec = msgsPerSec * Float64(msgSize) / (1024.0 * 1024.0)
    let usPerMsg = elapsedMs * 1000.0 / Float64(count)
    println("${label} | ${msgSize}B | ${count} msgs | ${elapsedMs}ms | ${usPerMsg} us/msg | ${msgsPerSec} msg/s | ${mbPerSec} MB/s")
}

func benchLatency(count: Int64, transport: String): Unit {
    let ctx = ZmqContext()
    let rep = ctx.socket(SocketType.REP)
    let req = ctx.socket(SocketType.REQ)

    let addr = makeAddr(transport, "latency")
    rep.bind(addr)
    req.connect(connectAddr(transport, addr))

    let payload = Array<UInt8>(64, repeat: 65)

    let fut = spawn {
        var i: Int64 = 0
        while (i < WARMUP_MSG_COUNT + count) {
            let msg = rep.recv()
            rep.send(msg)
            i++
        }
        rep.close()
    }

    var i: Int64 = 0
    while (i < WARMUP_MSG_COUNT) {
        req.send(payload)
        req.recv()
        i++
    }

    let start = DateTime.now()
    i = 0
    while (i < count) {
        req.send(payload)
        req.recv()
        i++
    }
    let elapsedNs = (DateTime.now() - start).toNanoseconds()

    fut.get()
    req.close()
    ctx.close()

    let elapsedMs = Float64(elapsedNs) / 1_000_000.0
    let usPerTrip = elapsedMs * 1000.0 / Float64(count)
    println("Latency (${transport}) | ${count} roundtrips | ${elapsedMs}ms | ${usPerTrip} us/trip")
}

func benchMultipart(frameCount: Int64, frameSize: Int64, count: Int64, transport: String): Unit {
    let ctx = ZmqContext()
    let pull = ctx.socket(SocketType.PULL)
    let push = ctx.socket(SocketType.PUSH)

    let addr = makeAddr(transport, "multi-${frameCount}x${frameSize}")
    pull.bind(addr)
    push.connect(connectAddr(transport, addr))

    let frames = Array<Array<UInt8>>(frameCount, repeat: makePayload(frameSize))

    let fut = spawn {
        var i: Int64 = 0
        while (i < WARMUP_MSG_COUNT + count) {
            pull.recvMultipart()
            i++
        }
        pull.close()
    }

    var i: Int64 = 0
    while (i < WARMUP_MSG_COUNT) {
        push.sendMultipart(frames)
        i++
    }

    let start = DateTime.now()
    i = 0
    while (i < count) {
        push.sendMultipart(frames)
        i++
    }
    let elapsedNs = (DateTime.now() - start).toNanoseconds()

    fut.get()
    push.close()
    ctx.close()

    let elapsedMs = Float64(elapsedNs) / 1_000_000.0
    let totalBytes = count * frameCount * frameSize
    let msgsPerSec = Float64(count) / (elapsedMs / 1000.0)
    let mbPerSec = Float64(totalBytes) / (elapsedMs / 1000.0) / (1024.0 * 1024.0)
    println("Multipart ${frameCount}x${frameSize}B | ${count} msgs | ${elapsedMs}ms | ${msgsPerSec} msg/s | ${mbPerSec} MB/s")
}

main(): Int64 {
    println("=== zmq benchmark ===")
    println()

    println("--- Throughput (inproc) ---")
    println("Benchmark          | MsgSize | Count      | Time   | Latency  | Throughput      | Bandwidth")
    benchThroughput("inproc", 64, BENCH_MSG_COUNT, "inproc")
    benchThroughput("inproc", 1024, BENCH_MSG_COUNT, "inproc")
    benchThroughput("inproc", 65536, BENCH_MSG_COUNT, "inproc")
    benchThroughput("inproc", 262144, 10000, "inproc")
    println()

    println("--- Throughput (tcp) ---")
    benchThroughput("tcp    ", 64, BENCH_MSG_COUNT, "tcp")
    benchThroughput("tcp    ", 1024, BENCH_MSG_COUNT, "tcp")
    benchThroughput("tcp    ", 65536, BENCH_MSG_COUNT, "tcp")
    benchThroughput("tcp    ", 262144, 10000, "tcp")
    println()

    println("--- Latency ---")
    benchLatency(BENCH_MSG_COUNT, "inproc")
    benchLatency(BENCH_MSG_COUNT, "tcp")
    println()

    println("--- Multipart ---")
    benchMultipart(2, 1024, BENCH_MSG_COUNT, "inproc")
    benchMultipart(10, 256, BENCH_MSG_COUNT, "inproc")
    benchMultipart(2, 1024, BENCH_MSG_COUNT, "tcp")
    benchMultipart(10, 256, BENCH_MSG_COUNT, "tcp")
    println()

    0
}
