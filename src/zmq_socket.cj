package zmq

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

    public func unbind(addr: String): Unit {
        let cs = stringToCString(addr)
        unsafe {
            checkResult(zmq_unbind(handle, cs))
        }
        freeCString(cs)
    }

    public func disconnect(addr: String): Unit {
        let cs = stringToCString(addr)
        unsafe {
            checkResult(zmq_disconnect(handle, cs))
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

    public func setIntOption(option: SocketOption, value: Int32): Unit {
        var val = value
        var size = UIntNative(4)
        unsafe {
            checkResult(zmq_setsockopt(handle, option.value, CPointer<Unit>(CPointer<Int32>(inout val)), size))
        }
    }

    public func getIntOption(option: SocketOption): Int32 {
        var val: Int32 = 0
        var size = UIntNative(4)
        unsafe {
            checkResult(zmq_getsockopt(handle, option.value, CPointer<Unit>(CPointer<Int32>(inout val)), CPointer<UIntNative>(inout size)))
        }
        val
    }

    public func setInt64Option(option: SocketOption, value: Int64): Unit {
        var val = value
        var size = UIntNative(8)
        unsafe {
            checkResult(zmq_setsockopt(handle, option.value, CPointer<Unit>(CPointer<Int64>(inout val)), size))
        }
    }

    public func getInt64Option(option: SocketOption): Int64 {
        var val: Int64 = 0
        var size = UIntNative(8)
        unsafe {
            checkResult(zmq_getsockopt(handle, option.value, CPointer<Unit>(CPointer<Int64>(inout val)), CPointer<UIntNative>(inout size)))
        }
        val
    }

    public func setUInt64Option(option: SocketOption, value: UInt64): Unit {
        var val = value
        var size = UIntNative(8)
        unsafe {
            checkResult(zmq_setsockopt(handle, option.value, CPointer<Unit>(CPointer<UInt64>(inout val)), size))
        }
    }

    public func getUInt64Option(option: SocketOption): UInt64 {
        var val: UInt64 = 0
        var size = UIntNative(8)
        unsafe {
            checkResult(zmq_getsockopt(handle, option.value, CPointer<Unit>(CPointer<UInt64>(inout val)), CPointer<UIntNative>(inout size)))
        }
        val
    }

    public func setBinaryOption(option: SocketOption, value: Array<UInt8>): Unit {
        unsafe {
            let handle2 = acquireArrayRawData<UInt8>(value)
            let rc = zmq_setsockopt(handle, option.value, CPointer<Unit>(handle2.pointer), UIntNative(value.size))
            releaseArrayRawData<UInt8>(handle2)
            checkResult(rc)
        }
    }

    public func getBinaryOption(option: SocketOption): Array<UInt8> {
        let maxLen = 256
        var size = UIntNative(maxLen)
        let buf = Array<UInt8>(maxLen, repeat: 0)
        unsafe {
            let handle2 = acquireArrayRawData<UInt8>(buf)
            let rc = zmq_getsockopt(handle, option.value, CPointer<Unit>(handle2.pointer), CPointer<UIntNative>(inout size))
            releaseArrayRawData<UInt8>(handle2)
            checkResult(rc)
        }
        let actualLen = Int64(size)
        if (actualLen == maxLen) {
            buf
        } else {
            let result = Array<UInt8>(actualLen, repeat: 0)
            var i: Int64 = 0
            while (i < actualLen) {
                result[i] = buf[i]
                i++
            }
            result
        }
    }

    public func setStringOption(option: SocketOption, value: String): Unit {
        let cs = stringToCString(value)
        unsafe {
            checkResult(zmq_setsockopt(handle, option.value, CPointer<Unit>(cs.getChars()), UIntNative(value.size)))
        }
        freeCString(cs)
    }

    public func setSubscribe(topic: String): Unit {
        setStringOption(SocketOption.SUBSCRIBE, topic)
    }

    public func setUnsubscribe(topic: String): Unit {
        setStringOption(SocketOption.UNSUBSCRIBE, topic)
    }
}
