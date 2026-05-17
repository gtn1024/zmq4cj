package zmq

let ZMQ_ENOTSOCK: Int32 = 156384721
let ZMQ_ETERM_VAL: Int32 = 156384765

public class ZmqProxy {
    public static func start(frontend: ZmqSocket, backend: ZmqSocket, capture: ?ZmqSocket): Unit {
        if (frontend.isClosed() || backend.isClosed()) {
            throw ZmqError(ZMQ_ENOTSOCK)
        }
        let capturePtr = if (let Some(s) <- capture) {
            if (s.isClosed()) {
                throw ZmqError(ZMQ_ENOTSOCK)
            }
            s.handle
        } else {
            CPointer<Unit>()
        }
        unsafe {
            let rc = zmq_proxy(frontend.handle, backend.handle, capturePtr)
            if (rc == -1) {
                let err = zmq_errno()
                if (err != ZMQ_ETERM_VAL) {
                    throw ZmqError(err)
                }
            }
        }
    }

    public static func start(frontend: ZmqSocket, backend: ZmqSocket): Unit {
        start(frontend, backend, None)
    }

    public static func startSteerable(frontend: ZmqSocket, backend: ZmqSocket, capture: ?ZmqSocket, control: ZmqSocket): Unit {
        if (frontend.isClosed() || backend.isClosed() || control.isClosed()) {
            throw ZmqError(ZMQ_ENOTSOCK)
        }
        let capturePtr = if (let Some(s) <- capture) {
            if (s.isClosed()) {
                throw ZmqError(ZMQ_ENOTSOCK)
            }
            s.handle
        } else {
            CPointer<Unit>()
        }
        unsafe {
            let rc = zmq_proxy_steerable(frontend.handle, backend.handle, capturePtr, control.handle)
            if (rc == -1) {
                let err = zmq_errno()
                if (err != ZMQ_ETERM_VAL) {
                    throw ZmqError(err)
                }
            }
        }
    }

    public static func startSteerable(frontend: ZmqSocket, backend: ZmqSocket, control: ZmqSocket): Unit {
        startSteerable(frontend, backend, None, control)
    }
}
