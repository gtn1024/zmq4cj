package zmq4cj

import std.collection.ArrayList

public class ZmqSocket <: Resource {
    var handle: CPointer<Unit>

    init(handle: CPointer<Unit>) {
        this.handle = handle
    }

    public func isClosed(): Bool {
        handle.isNull()
    }

    public func close(): Unit {
        if (isClosed()) {
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
        let msg = unsafe { LibC.malloc<ZmqMsg>(count: 1) }
        unsafe { checkResult(zmq_msg_init_size(msg, UIntNative(data.size))) }
        let dataPtr = unsafe { CPointer<UInt8>(zmq_msg_data(msg)) }
        copyArrayToCPointer(data, dataPtr)
        let rc = unsafe { zmq_msg_send(msg, handle, flags) }
        if (rc == -1) {
            let err = unsafe { zmq_errno() }
            unsafe { zmq_msg_close(msg) }
            unsafe { LibC.free(msg) }
            throw ZmqError(err)
        }
        unsafe { zmq_msg_close(msg) }
        unsafe { LibC.free(msg) }
    }

    public func send(data: Array<UInt8>): Unit {
        send(data, 0)
    }

    public func recv(flags: Int32): Array<UInt8> {
        let msg = unsafe { LibC.malloc<ZmqMsg>(count: 1) }
        unsafe { zmq_msg_init(msg) }
        let rc = unsafe { zmq_msg_recv(msg, handle, flags) }
        if (rc == -1) {
            unsafe { zmq_msg_close(msg) }
            unsafe { LibC.free(msg) }
            throw ZmqError(unsafe { zmq_errno() })
        }
        let size = unsafe { zmq_msg_size(msg) }
        let data = unsafe { zmq_msg_data(msg) }
        let dataPtr = unsafe { CPointer<UInt8>(data) }
        let result = copyCPointerToArray(dataPtr, Int64(size))
        unsafe { zmq_msg_close(msg) }
        unsafe { LibC.free(msg) }
        result
    }

    public func recv(): Array<UInt8> {
        recv(0)
    }

    public func hasReceiveMore(): Bool {
        var more: Int32 = 0
        unsafe {
            let morePtr = LibC.malloc<Int32>(count: 1)
            let sizePtr = LibC.malloc<UIntNative>(count: 1)
            (sizePtr + 0).write(UIntNative(4))
            zmq_getsockopt(handle, SocketOption.RCVMORE.value, CPointer<Unit>(morePtr), sizePtr)
            more = (morePtr + 0).read()
            LibC.free(morePtr)
            LibC.free(sizePtr)
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
