package zmq

import std.unittest.*
import std.unittest.testmacro.*
import std.sync.SyncCounter
import std.collection.ArrayList

@Test
public class ZmqPatternTest {
    @TestCase
    func testReqRep(): Unit {
        let ctx = ZmqContext()
        let rep = ctx.socket(SocketType.REP)
        let req = ctx.socket(SocketType.REQ)

        rep.bind("tcp://*:5555")
        req.connect("tcp://localhost:5555")

        let fut = spawn {
            let msg = rep.recv()
            let reply = "World".toArray()
            rep.send(reply)
            msg
        }

        sleep(Duration.millisecond * 100)
        req.send("Hello".toArray())
        let response = req.recv()

        let reqMsg = fut.get()
        @Assert(String.fromUtf8(reqMsg), "Hello")
        @Assert(String.fromUtf8(response), "World")

        req.close()
        rep.close()
        ctx.close()
    }

    @TestCase
    func testPubSub(): Unit {
        let ctx = ZmqContext()
        let pub = ctx.socket(SocketType.PUB)
        let sub = ctx.socket(SocketType.SUB)

        pub.bind("tcp://*:5556")
        sub.connect("tcp://localhost:5556")
        sub.setSubscribe("weather.")

        sleep(Duration.millisecond * 200)

        pub.send("news.headline=...".toArray())
        pub.send("weather.temp=25".toArray())

        let msg = sub.recv()
        @Assert(String.fromUtf8(msg), "weather.temp=25")

        pub.close()
        sub.close()
        ctx.close()
    }

    @TestCase
    func testDealerRouter(): Unit {
        let ctx = ZmqContext()
        let router = ctx.socket(SocketType.ROUTER)
        let dealer = ctx.socket(SocketType.DEALER)

        router.bind("tcp://*:5558")
        dealer.connect("tcp://localhost:5558")

        sleep(Duration.millisecond * 100)

        dealer.send("message".toArray())

        let identity = router.recv()
        let body = router.recv()
        @Assert(String.fromUtf8(body), "message")
        @Assert(identity.size > 0, true)

        dealer.close()
        router.close()
        ctx.close()
    }

    @TestCase
    func testPair(): Unit {
        let ctx = ZmqContext()
        let pairA = ctx.socket(SocketType.PAIR)
        let pairB = ctx.socket(SocketType.PAIR)

        pairA.bind("inproc://pair-test")
        pairB.connect("inproc://pair-test")

        pairA.send("ping".toArray())
        let msgB = pairB.recv()
        @Assert(String.fromUtf8(msgB), "ping")

        pairB.send("pong".toArray())
        let msgA = pairA.recv()
        @Assert(String.fromUtf8(msgA), "pong")

        pairA.close()
        pairB.close()
        ctx.close()
    }

    @TestCase
    func testPushPull(): Unit {
        let ctx = ZmqContext()
        let pull = ctx.socket(SocketType.PULL)
        let push = ctx.socket(SocketType.PUSH)

        pull.bind("tcp://*:5557")
        push.connect("tcp://localhost:5557")

        sleep(Duration.millisecond * 100)

        push.send("task-1".toArray())
        let msg = pull.recv()
        @Assert(String.fromUtf8(msg), "task-1")

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testMultipartPushPull(): Unit {
        let ctx = ZmqContext()
        let pull = ctx.socket(SocketType.PULL)
        let push = ctx.socket(SocketType.PUSH)

        pull.bind("tcp://*:5560")
        push.connect("tcp://localhost:5560")

        sleep(Duration.millisecond * 100)

        push.sendMultipart([
            "header".toArray(),
            "payload".toArray()
        ])

        let frames = pull.recvMultipart()
        @Assert(frames.size, 2)
        @Assert(String.fromUtf8(frames[0]), "header")
        @Assert(String.fromUtf8(frames[1]), "payload")

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testMultipartRouterDealer(): Unit {
        let ctx = ZmqContext()
        let router = ctx.socket(SocketType.ROUTER)
        let dealer = ctx.socket(SocketType.DEALER)

        router.bind("tcp://*:5561")
        dealer.connect("tcp://localhost:5561")

        sleep(Duration.millisecond * 100)

        dealer.sendMultipart([
            "part1".toArray(),
            "part2".toArray(),
            "part3".toArray()
        ])

        let identity = router.recv()
        let frames = router.recvMultipart()
        @Assert(frames.size, 3)
        @Assert(String.fromUtf8(frames[0]), "part1")
        @Assert(String.fromUtf8(frames[1]), "part2")
        @Assert(String.fromUtf8(frames[2]), "part3")
        @Assert(identity.size > 0, true)

        dealer.close()
        router.close()
        ctx.close()
    }

    @TestCase
    func testHasReceiveMore(): Unit {
        let ctx = ZmqContext()
        let pull = ctx.socket(SocketType.PULL)
        let push = ctx.socket(SocketType.PUSH)

        pull.bind("tcp://*:5562")
        push.connect("tcp://localhost:5562")

        sleep(Duration.millisecond * 100)

        push.sendMultipart([
            "frame1".toArray(),
            "frame2".toArray(),
            "frame3".toArray()
        ])

        let f1 = pull.recv(0)
        @Assert(String.fromUtf8(f1), "frame1")
        @Assert(pull.hasReceiveMore(), true)

        let f2 = pull.recv(0)
        @Assert(String.fromUtf8(f2), "frame2")
        @Assert(pull.hasReceiveMore(), true)

        let f3 = pull.recv(0)
        @Assert(String.fromUtf8(f3), "frame3")
        @Assert(pull.hasReceiveMore(), false)

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testMultipartEmptyFrame(): Unit {
        let ctx = ZmqContext()
        let pull = ctx.socket(SocketType.PULL)
        let push = ctx.socket(SocketType.PUSH)

        pull.bind("tcp://*:5563")
        push.connect("tcp://localhost:5563")

        sleep(Duration.millisecond * 100)

        push.sendMultipart([
            "header".toArray(),
            Array<UInt8>()
        ])

        let frames = pull.recvMultipart()
        @Assert(frames.size, 2)
        @Assert(String.fromUtf8(frames[0]), "header")
        @Assert(frames[1].size, 0)

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testRecvMultipartSingleFrame(): Unit {
        let ctx = ZmqContext()
        let pull = ctx.socket(SocketType.PULL)
        let push = ctx.socket(SocketType.PUSH)

        pull.bind("tcp://*:5564")
        push.connect("tcp://localhost:5564")

        sleep(Duration.millisecond * 100)

        push.send("single".toArray())

        let frames = pull.recvMultipart()
        @Assert(frames.size, 1)
        @Assert(String.fromUtf8(frames[0]), "single")

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testSocketConcurrentClose(): Unit {
        let ctx = ZmqContext()
        let sock = ctx.socket(SocketType.PAIR)
        let counter = SyncCounter(10)
        for (_ in 0..10) {
            spawn {
                sock.close()
                counter.dec()
            }
        }
        counter.waitUntilZero()
        @Assert(sock.isClosed(), true)
        ctx.close()
    }

    @TestCase
    func testContextConcurrentClose(): Unit {
        let ctx = ZmqContext()
        let counter = SyncCounter(10)
        for (_ in 0..10) {
            spawn {
                ctx.close()
                counter.dec()
            }
        }
        counter.waitUntilZero()
        @Assert(ctx.isClosed(), true)
    }

    @TestCase
    func testContextSocketAfterClose(): Unit {
        let ctx = ZmqContext()
        ctx.close()
        var thrown = false
        try {
            ctx.socket(SocketType.REQ)
        } catch (_: ZmqError) {
            thrown = true
        }
        @Assert(thrown, true)
    }

    @TestCase
    func testSocketCloseIdempotent(): Unit {
        let ctx = ZmqContext()
        let sock = ctx.socket(SocketType.PAIR)
        sock.close()
        sock.close()
        sock.close()
        @Assert(sock.isClosed(), true)
        ctx.close()
    }

    @TestCase
    func testContextCloseIdempotent(): Unit {
        let ctx = ZmqContext()
        ctx.close()
        ctx.close()
        ctx.close()
        @Assert(ctx.isClosed(), true)
    }

    @TestCase
    func testLargeMessage(): Unit {
        let ctx = ZmqContext()
        let push = ctx.socket(SocketType.PUSH)
        let pull = ctx.socket(SocketType.PULL)

        push.bind("inproc://large-msg-test")
        pull.connect("inproc://large-msg-test")

        let size = 1024 * 1024
        let sent = Array<UInt8>(size, repeat: 0)
        for (i in 0..size) {
            sent[i] = UInt8(i % 256)
        }

        push.send(sent)
        let received = pull.recv()

        @Assert(received.size, Int64(size))
        @Assert(received == sent, true)

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testBinaryDataWithZeros(): Unit {
        let ctx = ZmqContext()
        let push = ctx.socket(SocketType.PUSH)
        let pull = ctx.socket(SocketType.PULL)

        push.bind("inproc://binary-test")
        pull.connect("inproc://binary-test")

        let sent = Array<UInt8>(256, repeat: 0)
        for (i in 0..256) {
            sent[i] = UInt8(i)
        }

        push.send(sent)
        let received = pull.recv()

        @Assert(received.size, 256)
        @Assert(received == sent, true)

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testRapidSendRecv(): Unit {
        let ctx = ZmqContext()
        let push = ctx.socket(SocketType.PUSH)
        let pull = ctx.socket(SocketType.PULL)

        push.bind("inproc://rapid-test")
        pull.connect("inproc://rapid-test")

        let count = 1000
        let fut = spawn {
            var received = 0
            while (received < count) {
                pull.recv()
                received++
            }
            received
        }

        for (i in 0..count) {
            push.send("msg".toArray())
        }

        let total = fut.get()
        @Assert(total, Int64(count))

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testSetGetIntOption(): Unit {
        let ctx = ZmqContext()
        let sock = ctx.socket(SocketType.REQ)

        sock.setIntOption(SocketOption.LINGER, 0)
        let linger = sock.getIntOption(SocketOption.LINGER)
        @Assert(linger, 0)

        sock.setIntOption(SocketOption.LINGER, 100)
        let linger2 = sock.getIntOption(SocketOption.LINGER)
        @Assert(linger2, 100)

        sock.close()
        ctx.close()
    }

    @TestCase
    func testRcvTimeout(): Unit {
        let ctx = ZmqContext()
        let rep = ctx.socket(SocketType.REP)
        let req = ctx.socket(SocketType.REQ)

        rep.bind("tcp://*:5570")
        req.connect("tcp://localhost:5570")

        req.setIntOption(SocketOption.RCVTIMEO, 100)

        var timedOut = false
        try {
            req.recv()
        } catch (e: ZmqError) {
            timedOut = true
        }
        @Assert(timedOut, true)

        req.close()
        rep.close()
        ctx.close()
    }

    @TestCase
    func testUnsubscribe(): Unit {
        let ctx = ZmqContext()
        let pub = ctx.socket(SocketType.PUB)
        let sub = ctx.socket(SocketType.SUB)

        pub.bind("tcp://*:5571")
        sub.connect("tcp://localhost:5571")
        sub.setSubscribe("")
        sub.setStringOption(SocketOption.UNSUBSCRIBE, "")

        sleep(Duration.millisecond * 100)

        pub.send("should-not-receive".toArray())

        sub.setIntOption(SocketOption.RCVTIMEO, 200)
        var received = false
        try {
            sub.recv()
            received = true
        } catch (_: ZmqError) {
        }
        @Assert(received, false)

        pub.close()
        sub.close()
        ctx.close()
    }

    @TestCase
    func testPollSingleSocket(): Unit {
        let ctx = ZmqContext()
        let push = ctx.socket(SocketType.PUSH)
        let pull = ctx.socket(SocketType.PULL)

        push.bind("tcp://*:5580")
        pull.connect("tcp://localhost:5580")

        push.send("hello".toArray())

        sleep(Duration.millisecond * 100)

        let list = ArrayList<PollItem>()
        list.add(PollItem(pull, PollEvent.POLLIN.value))
        let rc = ZmqPoll.poll(list.toArray(), 1000)
        @Assert(rc, 1)
        @Assert((list[0].revents & PollEvent.POLLIN.value) != Int16(0), true)

        let msg = pull.recv()
        @Assert(String.fromUtf8(msg), "hello")

        push.close()
        pull.close()
        ctx.close()
    }

    @TestCase
    func testPollTimeout(): Unit {
        let ctx = ZmqContext()
        let pull = ctx.socket(SocketType.PULL)
        pull.bind("tcp://*:5581")

        let list = ArrayList<PollItem>()
        list.add(PollItem(pull, PollEvent.POLLIN.value))
        let rc = ZmqPoll.poll(list.toArray(), 100)
        @Assert(rc, 0)
        @Assert(list[0].revents, Int16(0))

        pull.close()
        ctx.close()
    }

    @TestCase
    func testPollMultipleSockets(): Unit {
        let ctx = ZmqContext()
        let push1 = ctx.socket(SocketType.PUSH)
        let pull1 = ctx.socket(SocketType.PULL)
        let pull2 = ctx.socket(SocketType.PULL)

        push1.bind("tcp://*:5582")
        pull1.connect("tcp://localhost:5582")
        pull2.bind("tcp://*:5583")

        push1.send("msg1".toArray())
        sleep(Duration.millisecond * 100)

        let list = ArrayList<PollItem>()
        list.add(PollItem(pull1, PollEvent.POLLIN.value))
        list.add(PollItem(pull2, PollEvent.POLLIN.value))
        let rc = ZmqPoll.poll(list.toArray(), 1000)
        @Assert(rc, 1)
        @Assert((list[0].revents & PollEvent.POLLIN.value) != Int16(0), true)
        @Assert(list[1].revents, Int16(0))

        push1.close()
        pull1.close()
        pull2.close()
        ctx.close()
    }

    @TestCase
    func testXpubXsub(): Unit {
        let ctx = ZmqContext()
        let xpub = ctx.socket(SocketType.XPUB)
        let sub = ctx.socket(SocketType.SUB)

        xpub.bind("tcp://*:5590")
        sub.connect("tcp://localhost:5590")

        sleep(Duration.millisecond * 200)

        sub.setSubscribe("weather.")
        sleep(Duration.millisecond * 100)

        let subMsg = xpub.recv()
        let subCmd = Array<UInt8>(1 + "weather.".size, {i: Int64 =>
            if (i == 0) { UInt8(1) } else { "weather.".toArray()[Int64(i - 1)] }
        })
        @Assert(subMsg[0], UInt8(1))
        @Assert(String.fromUtf8(Array<UInt8>(subMsg.size - 1, {i: Int64 => subMsg[Int64(i + 1)]})), "weather.")

        xpub.send("weather.london: rain, 15C".toArray())
        sleep(Duration.millisecond * 100)

        let msg = sub.recv()
        @Assert(String.fromUtf8(msg), "weather.london: rain, 15C")

        xpub.close()
        sub.close()
        ctx.close()
    }

    @TestCase
    func testStreamSocket(): Unit {
        let ctx = ZmqContext()
        let stream = ctx.socket(SocketType.STREAM)
        stream.bind("tcp://*:5591")
        @Assert(stream.isClosed(), false)
        stream.close()
        ctx.close()
    }

    @TestCase
    func testUnbind(): Unit {
        let ctx = ZmqContext()
        let rep = ctx.socket(SocketType.REP)
        let addr = "inproc://test-unbind"
        rep.bind(addr)
        rep.unbind(addr)
        rep.close()
        ctx.close()
    }

    @TestCase
    func testUnbindNonexistent(): Unit {
        let ctx = ZmqContext()
        let rep = ctx.socket(SocketType.REP)
        var caught = false
        try {
            rep.unbind("tcp://*:5593")
        } catch (_: ZmqError) {
            caught = true
        }
        @Assert(caught, true)
        rep.close()
        ctx.close()
    }

    @TestCase
    func testDisconnect(): Unit {
        let ctx = ZmqContext()
        let rep = ctx.socket(SocketType.REP)
        let req = ctx.socket(SocketType.REQ)
        let addr = "inproc://test-disconnect"
        rep.bind(addr)
        req.connect(addr)
        req.disconnect(addr)
        req.close()
        rep.close()
        ctx.close()
    }

    @TestCase
    func testDisconnectNonexistent(): Unit {
        let ctx = ZmqContext()
        let req = ctx.socket(SocketType.REQ)
        var caught = false
        try {
            req.disconnect("inproc://nonexistent")
        } catch (_: ZmqError) {
            caught = true
        }
        @Assert(caught, true)
        req.close()
        ctx.close()
    }

    @TestCase
    func testInt32Options(): Unit {
        let ctx = ZmqContext()
        let socket = ctx.socket(SocketType.REQ)

        socket.setIntOption(SocketOption.RECONNECT_IVL, 5000)
        @Assert(socket.getIntOption(SocketOption.RECONNECT_IVL), 5000)

        socket.setIntOption(SocketOption.BACKLOG, 100)
        @Assert(socket.getIntOption(SocketOption.BACKLOG), 100)

        socket.setIntOption(SocketOption.LINGER, 1000)
        @Assert(socket.getIntOption(SocketOption.LINGER), 1000)

        socket.close()
        ctx.close()
    }

    @TestCase
    func testInt64Option(): Unit {
        let ctx = ZmqContext()
        let socket = ctx.socket(SocketType.REQ)

        socket.setInt64Option(SocketOption.MAXMSGSIZE, 1048576)
        @Assert(socket.getInt64Option(SocketOption.MAXMSGSIZE), 1048576)

        socket.close()
        ctx.close()
    }

    @TestCase
    func testUInt64Option(): Unit {
        let ctx = ZmqContext()
        let socket = ctx.socket(SocketType.REQ)

        socket.setUInt64Option(SocketOption.AFFINITY, 1)
        @Assert(socket.getUInt64Option(SocketOption.AFFINITY), 1)

        socket.close()
        ctx.close()
    }

    @TestCase
    func testBinaryOption(): Unit {
        let ctx = ZmqContext()
        let router = ctx.socket(SocketType.ROUTER)

        let identity = Array<UInt8>(3, repeat: 0)
        identity[0] = 1
        identity[1] = 2
        identity[2] = 3
        router.setBinaryOption(SocketOption.IDENTITY, identity)
        let readBack = router.getBinaryOption(SocketOption.IDENTITY)
        @Assert(readBack.size, 3)
        @Assert(readBack[0], 1)
        @Assert(readBack[1], 2)
        @Assert(readBack[2], 3)

        router.close()
        ctx.close()
    }

    @TestCase
    func testSetUnsubscribe(): Unit {
        let ctx = ZmqContext()
        let sub = ctx.socket(SocketType.SUB)
        sub.setSubscribe("topic1")
        sub.setUnsubscribe("topic1")
        sub.close()
        ctx.close()
    }

    @TestCase
    func testProxyPushPull(): Unit {
        let ctx = ZmqContext()
        let frontend = ctx.socket(SocketType.PULL)
        let backend = ctx.socket(SocketType.PUSH)
        let control = ctx.socket(SocketType.PAIR)

        frontend.bind("tcp://*:5630")
        backend.bind("tcp://*:5631")
        control.bind("inproc://proxy-ctrl")

        let counter = SyncCounter(1)
        spawn {
            ZmqProxy.startSteerable(frontend, backend, control)
            counter.dec()
        }

        sleep(Duration.millisecond * 100)

        let push = ctx.socket(SocketType.PUSH)
        let pull = ctx.socket(SocketType.PULL)
        push.connect("tcp://localhost:5630")
        pull.connect("tcp://localhost:5631")
        pull.setIntOption(SocketOption.RCVTIMEO, 3000)

        sleep(Duration.millisecond * 200)

        push.send("through-proxy".toArray())
        let msg = pull.recv()
        @Assert(String.fromUtf8(msg), "through-proxy")

        let ctrlClient = ctx.socket(SocketType.PAIR)
        ctrlClient.connect("inproc://proxy-ctrl")
        sleep(Duration.millisecond * 50)
        ctrlClient.send("TERMINATE".toArray())

        counter.waitUntilZero()

        ctrlClient.close()
        push.close()
        pull.close()
        frontend.close()
        backend.close()
        control.close()
        ctx.close()
    }

    @TestCase
    func testProxySteerableTerminate(): Unit {
        let ctx = ZmqContext()
        let xsub = ctx.socket(SocketType.XSUB)
        let xpub = ctx.socket(SocketType.XPUB)
        let control = ctx.socket(SocketType.PAIR)

        xsub.bind("tcp://*:5620")
        xpub.bind("tcp://*:5621")
        control.bind("inproc://proxy-control-steerable")

        let counter = SyncCounter(1)
        spawn {
            ZmqProxy.startSteerable(xsub, xpub, control)
            counter.dec()
        }

        sleep(Duration.millisecond * 100)

        let client = ctx.socket(SocketType.PAIR)
        client.connect("inproc://proxy-control-steerable")
        sleep(Duration.millisecond * 100)
        client.send("TERMINATE".toArray())

        counter.waitUntilZero()

        client.close()
        control.close()
        xsub.close()
        xpub.close()
        ctx.close()
    }

    @TestCase
    func testProxyContextTerminate(): Unit {
        let ctx = ZmqContext()
        let frontend = ctx.socket(SocketType.PULL)
        let backend = ctx.socket(SocketType.PUSH)
        let control = ctx.socket(SocketType.PAIR)

        frontend.bind("tcp://*:5640")
        backend.bind("tcp://*:5641")
        control.bind("inproc://proxy-term-ctrl")

        let counter = SyncCounter(1)
        spawn {
            ZmqProxy.startSteerable(frontend, backend, control)
            frontend.close()
            backend.close()
            control.close()
            counter.dec()
        }

        sleep(Duration.millisecond * 100)

        let client = ctx.socket(SocketType.PAIR)
        client.connect("inproc://proxy-term-ctrl")
        sleep(Duration.millisecond * 50)
        client.send("TERMINATE".toArray())

        counter.waitUntilZero()
        client.close()
        ctx.close()
    }

    @TestCase
    func testProxyClosedSocket(): Unit {
        let ctx = ZmqContext()
        let frontend = ctx.socket(SocketType.PULL)
        let backend = ctx.socket(SocketType.PUSH)
        frontend.close()

        var caught = false
        try {
            ZmqProxy.start(frontend, backend)
        } catch (e: ZmqError) {
            caught = true
        }
        @Assert(caught, true)

        backend.close()
        ctx.close()
    }

    @TestCase
    func testProxyXpubXsubForwarding(): Unit {
        let ctx = ZmqContext()
        let xsub = ctx.socket(SocketType.XSUB)
        let xpub = ctx.socket(SocketType.XPUB)
        let control = ctx.socket(SocketType.PAIR)

        xsub.bind("tcp://*:5650")
        xpub.bind("tcp://*:5651")
        control.bind("inproc://proxy-xpubxsub-ctrl")

        let counter = SyncCounter(1)
        spawn {
            ZmqProxy.startSteerable(xsub, xpub, control)
            xsub.close()
            xpub.close()
            control.close()
            counter.dec()
        }

        sleep(Duration.millisecond * 100)

        let pub = ctx.socket(SocketType.PUB)
        let sub = ctx.socket(SocketType.SUB)
        pub.connect("tcp://localhost:5650")
        sub.connect("tcp://localhost:5651")
        sub.setSubscribe("")
        sub.setIntOption(SocketOption.RCVTIMEO, 3000)

        sleep(Duration.millisecond * 200)

        pub.send("xpubxsub-msg".toArray())
        let msg = sub.recv()
        @Assert(String.fromUtf8(msg), "xpubxsub-msg")

        let ctrlClient = ctx.socket(SocketType.PAIR)
        ctrlClient.connect("inproc://proxy-xpubxsub-ctrl")
        sleep(Duration.millisecond * 50)
        ctrlClient.send("TERMINATE".toArray())

        counter.waitUntilZero()

        ctrlClient.close()
        pub.close()
        sub.close()
        ctx.close()
    }
}

@Test
public class ZmqContextOptionTest {
    @TestCase
    func testSetGetIoThreads(): Unit {
        let ctx = ZmqContext()
        ctx.set(ContextOption.IO_THREADS, 2)
        let val = ctx.get(ContextOption.IO_THREADS)
        ctx.close()
        if (val != 2) {
            throw Exception("IO_THREADS should be 2, got ${val}")
        }
    }

    @TestCase
    func testGetSocketLimit(): Unit {
        let ctx = ZmqContext()
        let val = ctx.get(ContextOption.SOCKET_LIMIT)
        ctx.close()
        if (val <= 0) {
            throw Exception("SOCKET_LIMIT should be positive, got ${val}")
        }
    }

    @TestCase
    func testSetGetOnClosedContextThrows(): Unit {
        let ctx = ZmqContext()
        ctx.close()
        try {
            ctx.set(ContextOption.IO_THREADS, 4)
            throw Exception("should throw on closed context")
        } catch (_: ZmqError) {}
        try {
            ctx.get(ContextOption.IO_THREADS)
            throw Exception("should throw on closed context")
        } catch (_: ZmqError) {}
    }

    @TestCase
    func testSetGetMaxSockets(): Unit {
        let ctx = ZmqContext()
        ctx.set(ContextOption.MAX_SOCKETS, 512)
        let val = ctx.get(ContextOption.MAX_SOCKETS)
        ctx.close()
        if (val != 512) {
            throw Exception("MAX_SOCKETS should be 512, got ${val}")
        }
    }
}
