package zmq

public class ZmqProxy {
    public static func start(frontend: ZmqSocket, backend: ZmqSocket, capture: ?ZmqSocket): Unit {
        let capturePtr = if (let Some(s) <- capture) {
            s.handle
        } else {
            CPointer<Unit>()
        }
        unsafe {
            let rc = zmq_proxy(frontend.handle, backend.handle, capturePtr)
            if (rc == -1) {
                let err = zmq_errno()
                if (err != 78) {
                    throw ZmqError(err)
                }
            }
        }
    }

    public static func start(frontend: ZmqSocket, backend: ZmqSocket): Unit {
        start(frontend, backend, None)
    }

    public static func startSteerable(frontend: ZmqSocket, backend: ZmqSocket, capture: ?ZmqSocket, control: ZmqSocket): Unit {
        let capturePtr = if (let Some(s) <- capture) {
            s.handle
        } else {
            CPointer<Unit>()
        }
        unsafe {
            let rc = zmq_proxy_steerable(frontend.handle, backend.handle, capturePtr, control.handle)
            if (rc == -1) {
                let err = zmq_errno()
                if (err != 78) {
                    throw ZmqError(err)
                }
            }
        }
    }

    public static func startSteerable(frontend: ZmqSocket, backend: ZmqSocket, control: ZmqSocket): Unit {
        startSteerable(frontend, backend, None, control)
    }
}
