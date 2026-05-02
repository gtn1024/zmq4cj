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
        let bufSize: Int64 = 65536
        let buf = unsafe { LibC.malloc<UInt8>(count: bufSize) }
        let rc = unsafe { zmq_recv(handle, CPointer<Unit>(buf), UIntNative(bufSize), 0) }
        if (rc == -1) {
            unsafe { LibC.free(buf) }
            throw ZmqError(unsafe { zmq_errno() })
        }
        let result = copyCPointerToArray(buf, Int64(rc))
        unsafe { LibC.free(buf) }
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
