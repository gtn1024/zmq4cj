package zmq

public open class ZmqError <: Exception {
    public let errno: Int32

    public init(errno: Int32) {
        super(unsafe { zmq_strerror(errno).toString() })
        this.errno = errno
    }

    public open override func getClassName(): String {
        "ZmqError"
    }
}

func checkResult(rc: Int32): Unit {
    if (rc == -1) {
        throw ZmqError(unsafe { zmq_errno() })
    }
}
