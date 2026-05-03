package zmq4cj

import std.collection.ArrayList
import std.sync.AtomicBool

public class ZmqSocket <: Resource {
    var handle: CPointer<Unit>
    let closed = AtomicBool(false)

    init(handle: CPointer<Unit>) {
        this.handle = handle
    }

    public func isClosed(): Bool {
        closed.load()
    }

    public func close(): Unit {
        if (!closed.compareAndSwap(false, true)) {
            return
        }
        unsafe {
            checkResult(zmq_close(handle))
        }
        handle = CPointer<Unit>()
    }

    public func bind(addr: String): Unit {
        let cs = stringToCString(addr)
        unsafe {
            checkResult(zmq_bind(handle, cs))
        }
        freeCString(cs)
    }

    public func connect(addr: String): Unit {
        let cs = stringToCString(addr)
        unsafe {
            checkResult(zmq_connect(handle, cs))
        }
        freeCString(cs)
    }

    public func send(data: Array<UInt8>, flags: Int32): Unit {
        if (data.size == 0) {
            unsafe { checkResult(zmq_send(handle, CPointer<Unit>(), UIntNative(0), flags)) }
            return
        }
        unsafe {
            let handle2 = acquireArrayRawData<UInt8>(data)
            let rc = zmq_send(handle, CPointer<Unit>(handle2.pointer), UIntNative(data.size), flags)
            releaseArrayRawData<UInt8>(handle2)
            checkResult(rc)
        }
    }

    public func send(data: Array<UInt8>): Unit {
        send(data, 0)
    }

    public func recv(flags: Int32): Array<UInt8> {
        var msg = ZmqMsg()
        unsafe { zmq_msg_init(CPointer<ZmqMsg>(inout msg)) }
        let rc = unsafe { zmq_msg_recv(CPointer<ZmqMsg>(inout msg), handle, flags) }
        if (rc == -1) {
            unsafe { zmq_msg_close(CPointer<ZmqMsg>(inout msg)) }
            throw ZmqError(unsafe { zmq_errno() })
        }
        let size = unsafe { zmq_msg_size(CPointer<ZmqMsg>(inout msg)) }
        let data = unsafe { zmq_msg_data(CPointer<ZmqMsg>(inout msg)) }
        let dataPtr = unsafe { CPointer<UInt8>(data) }
        let result = copyCPointerToArray(dataPtr, Int64(size))
        unsafe { zmq_msg_close(CPointer<ZmqMsg>(inout msg)) }
        result
    }

    public func recv(): Array<UInt8> {
        recv(0)
    }

    public func hasReceiveMore(): Bool {
        var more: Int32 = 0
        var size: UIntNative = UIntNative(4)
        unsafe {
            zmq_getsockopt(handle, SocketOption.RCVMORE.value, CPointer<Unit>(CPointer<Int32>(inout more)), CPointer<UIntNative>(inout size))
            more = more
        }
        more == 1
    }

    public func sendMultipart(frames: Array<Array<UInt8>>): Unit {
        if (frames.size == 0) {
            throw ZmqError(22)
        }
        var i: Int64 = 0
        while (i < frames.size - 1) {
            send(frames[i], SendRecvFlags.SNDMORE.value)
            i++
        }
        send(frames[frames.size - 1])
    }

    public func recvMultipart(): Array<Array<UInt8>> {
        let frames = ArrayList<Array<UInt8>>()
        frames.add(recv(0))
        while (hasReceiveMore()) {
            frames.add(recv(0))
        }
        frames.toArray()
    }

    public func setSubscribe(topic: String): Unit {
        let bytes = topic.toArray()
        let buf = unsafe { LibC.malloc<UInt8>(count: bytes.size) }
        copyArrayToCPointer(bytes, buf)
        unsafe {
            checkResult(zmq_setsockopt(handle, SocketOption.SUBSCRIBE.value, CPointer<Unit>(buf), UIntNative(bytes.size)))
        }
        unsafe { LibC.free(buf) }
    }
}
