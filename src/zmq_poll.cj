package zmq4cj

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

public class ZmqPoll {
    public static func poll(items: Array<PollItem>, timeout: Int64): Int32 {
        let count = Int32(items.size)
        if (count == 0) {
            return 0
        }
        let buf = unsafe { LibC.malloc<UInt8>(count: Int64(count) * 16) }
        unsafe {
            var i: Int64 = 0
            while (i < Int64(count)) {
                let base = CPointer<Unit>(buf + i * 16)
                let socketPtr = CPointer<CPointer<Unit>>(base)
                socketPtr.write(items[i].socket.handle)
                let eventsPtr = CPointer<Int16>(CPointer<Unit>(buf + i * 16 + 12))
                eventsPtr.write(items[i].events)
                let reventsPtr = CPointer<Int16>(CPointer<Unit>(buf + i * 16 + 14))
                reventsPtr.write(Int16(0))
                i++
            }
        }
        let rc = unsafe { zmq_poll(CPointer<Unit>(buf), count, timeout) }
        if (rc == -1) {
            unsafe { LibC.free(buf) }
            throw ZmqError(unsafe { zmq_errno() })
        }
        unsafe {
            var i: Int64 = 0
            while (i < Int64(count)) {
                let reventsPtr = CPointer<Int16>(CPointer<Unit>(buf + i * 16 + 14))
                items[i].revents = reventsPtr.read()
                i++
            }
        }
        unsafe { LibC.free(buf) }
        rc
    }
}
