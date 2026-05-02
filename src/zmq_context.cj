package zmq4cj

public class ZmqContext <: Resource {
    var handle: CPointer<Unit>

    public init() {
        let ctx = unsafe { zmq_ctx_new() }
        if (ctx.isNull()) {
            throw ZmqError(unsafe { zmq_errno() })
        }
        handle = ctx
    }

    public func isClosed(): Bool {
        handle.isNull()
    }

    public func close(): Unit {
        if (isClosed()) {
            return
        }
        unsafe {
            checkResult(zmq_ctx_term(handle))
        }
        handle = CPointer<Unit>()
    }

    public func socket(type_: SocketType): ZmqSocket {
        if (isClosed()) {
            throw ZmqError(53)
        }
        let sock = unsafe { zmq_socket(handle, type_.value) }
        if (sock.isNull()) {
            throw ZmqError(unsafe { zmq_errno() })
        }
        ZmqSocket(sock)
    }
}
