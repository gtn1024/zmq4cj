package zmq4cj

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
}
