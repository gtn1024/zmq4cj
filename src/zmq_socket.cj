package zmq4cj

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

    public func send(data: Array<UInt8>): Unit {
        let buf = unsafe { LibC.malloc<UInt8>(count: data.size) }
        copyArrayToCPointer(data, buf)
        unsafe {
            checkResult(zmq_send(handle, CPointer<Unit>(buf), UIntNative(data.size), 0))
        }
        unsafe { LibC.free(buf) }
    }

    public func recv(): Array<UInt8> {
        let msg = unsafe { LibC.malloc<ZmqMsg>(count: 1) }
        unsafe { zmq_msg_init(msg) }
        let rc = unsafe { zmq_msg_recv(msg, handle, 0) }
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
