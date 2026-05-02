package zmq4cj

public class ZmqSocket <: Resource {
    var handle: CPointer<Unit>

    init(handle: CPointer<Unit>) {
        this.handle = handle
    }

    public func isClosed(): Bool {
        handle.isNull()
    }

    public func close(): Unit {}
}
