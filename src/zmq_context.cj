package zmq

import std.sync.{AtomicBool, Mutex}

public class ZmqContext <: Resource {
    var handle: CPointer<Unit>
    let closed = AtomicBool(false)
    let mutex = Mutex()

    public init() {
        let ctx = unsafe { zmq_ctx_new() }
        if (ctx.isNull()) {
            throw ZmqError(unsafe { zmq_errno() })
        }
        handle = ctx
    }

    public func isClosed(): Bool {
        closed.load()
    }

    public func close(): Unit {
        if (!closed.compareAndSwap(false, true)) {
            return
        }
        synchronized(mutex) {
            unsafe {
                checkResult(zmq_ctx_term(handle))
            }
            handle = CPointer<Unit>()
        }
    }

    public func set(option: ContextOption, value: Int32): Unit {
        synchronized(mutex) {
            if (closed.load()) {
                throw ZmqError(156384765)
            }
            unsafe {
                checkResult(zmq_ctx_set(handle, option.value, value))
            }
        }
    }

    public func get(option: ContextOption): Int32 {
        synchronized(mutex) {
            if (closed.load()) {
                throw ZmqError(156384765)
            }
            unsafe {
                let rc = zmq_ctx_get(handle, option.value)
                if (rc == -1) {
                    throw ZmqError(zmq_errno())
                }
                rc
            }
        }
    }

    public func socket(type_: SocketType): ZmqSocket {
        synchronized(mutex) {
            if (closed.load()) {
                throw ZmqError(53)
            }
            let sock = unsafe { zmq_socket(handle, type_.value) }
            if (sock.isNull()) {
                throw ZmqError(unsafe { zmq_errno() })
            }
            ZmqSocket(sock)
        }
    }
}
