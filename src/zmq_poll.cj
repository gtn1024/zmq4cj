package zmq

// zmq_fd_t (the fd field of zmq_pollitem_t) is platform-dependent (zmq.h):
//   Windows: a pointer-sized unsigned int (Win64=8B, Win32=4B) — zmq.h comment:
//            "Windows uses a pointer-sized unsigned integer to store the socket fd"
//   Unix   : int (4 bytes)
// Matching the width here lets the @C struct below inherit the correct C ABI
// layout (field offsets/stride) on every platform — no hand-computed byte
// offsets that silently desync and cause zmq_poll to read garbage events.
// UIntNative is pointer-sized, which matches the Windows rule exactly.
@When[os == "Windows"]
type ZmqFdT = UIntNative

@When[os != "Windows"]
type ZmqFdT = Int32

// 1:1 mirror of C's `struct zmq_pollitem_t`. The compiler lays it out per the
// C ABI of the target platform, so callers never deal with raw byte offsets.
@C
struct ZmqPollItem {
    var socket: CPointer<Unit> = CPointer<Unit>()
    var fd: ZmqFdT = 0
    var events: Int16 = 0
    var revents: Int16 = 0
}

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
        let buf = unsafe { LibC.malloc<ZmqPollItem>(count: Int64(count)) }
        unsafe {
            var i: Int64 = 0
            while (i < Int64(count)) {
                let p = CPointer<ZmqPollItem>(buf + i)
                var item = ZmqPollItem()
                item.socket = items[i].socket.handle
                item.fd = 0
                item.events = items[i].events
                item.revents = 0
                p.write(item)
                i++
            }
        }
        let rc = unsafe { zmq_poll(buf, count, timeout) }
        if (rc == -1) {
            unsafe { LibC.free(buf) }
            throw ZmqError(unsafe { zmq_errno() })
        }
        unsafe {
            var i: Int64 = 0
            while (i < Int64(count)) {
                let p = CPointer<ZmqPollItem>(buf + i)
                items[i].revents = p.read().revents
                i++
            }
        }
        unsafe { LibC.free(buf) }
        rc
    }
}
