package zmq4cj

import std.unittest.*
import std.unittest.testmacro.*
import std.time.*

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

        pub.send("weather.temp=25".toArray())
        pub.send("news.headline=...".toArray())

        let msg = sub.recv()
        @Assert(String.fromUtf8(msg), "weather.temp=25")

        pub.close()
        sub.close()
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
}
