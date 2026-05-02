package zmq4cj

foreign func zmq_ctx_new(): CPointer<Unit>

foreign func zmq_ctx_term(context: CPointer<Unit>): Int32

foreign func zmq_ctx_set(context: CPointer<Unit>, option: Int32, optval: Int32): Int32

foreign func zmq_ctx_get(context: CPointer<Unit>, option: Int32): Int32

foreign func zmq_socket(context: CPointer<Unit>, type_: Int32): CPointer<Unit>

foreign func zmq_close(s: CPointer<Unit>): Int32

foreign func zmq_setsockopt(s: CPointer<Unit>, option: Int32, optval: CPointer<Unit>, optvallen: UIntNative): Int32

foreign func zmq_getsockopt(s: CPointer<Unit>, option: Int32, optval: CPointer<Unit>, optvallen: CPointer<UIntNative>): Int32

foreign func zmq_bind(s: CPointer<Unit>, addr: CString): Int32

foreign func zmq_connect(s: CPointer<Unit>, addr: CString): Int32

foreign func zmq_unbind(s: CPointer<Unit>, addr: CString): Int32

foreign func zmq_disconnect(s: CPointer<Unit>, addr: CString): Int32

foreign func zmq_send(s: CPointer<Unit>, buf: CPointer<Unit>, len: UIntNative, flags: Int32): Int32

foreign func zmq_recv(s: CPointer<Unit>, buf: CPointer<Unit>, len: UIntNative, flags: Int32): Int32

foreign func zmq_errno(): Int32

foreign func zmq_strerror(errnum: Int32): CString

@C
struct ZmqMsg {
    var _0: UInt8 = 0
    var _1: UInt8 = 0
    var _2: UInt8 = 0
    var _3: UInt8 = 0
    var _4: UInt8 = 0
    var _5: UInt8 = 0
    var _6: UInt8 = 0
    var _7: UInt8 = 0
    var _8: UInt8 = 0
    var _9: UInt8 = 0
    var _10: UInt8 = 0
    var _11: UInt8 = 0
    var _12: UInt8 = 0
    var _13: UInt8 = 0
    var _14: UInt8 = 0
    var _15: UInt8 = 0
    var _16: UInt8 = 0
    var _17: UInt8 = 0
    var _18: UInt8 = 0
    var _19: UInt8 = 0
    var _20: UInt8 = 0
    var _21: UInt8 = 0
    var _22: UInt8 = 0
    var _23: UInt8 = 0
    var _24: UInt8 = 0
    var _25: UInt8 = 0
    var _26: UInt8 = 0
    var _27: UInt8 = 0
    var _28: UInt8 = 0
    var _29: UInt8 = 0
    var _30: UInt8 = 0
    var _31: UInt8 = 0
    var _32: UInt8 = 0
    var _33: UInt8 = 0
    var _34: UInt8 = 0
    var _35: UInt8 = 0
    var _36: UInt8 = 0
    var _37: UInt8 = 0
    var _38: UInt8 = 0
    var _39: UInt8 = 0
    var _40: UInt8 = 0
    var _41: UInt8 = 0
    var _42: UInt8 = 0
    var _43: UInt8 = 0
    var _44: UInt8 = 0
    var _45: UInt8 = 0
    var _46: UInt8 = 0
    var _47: UInt8 = 0
    var _48: UInt8 = 0
    var _49: UInt8 = 0
    var _50: UInt8 = 0
    var _51: UInt8 = 0
    var _52: UInt8 = 0
    var _53: UInt8 = 0
    var _54: UInt8 = 0
    var _55: UInt8 = 0
    var _56: UInt8 = 0
    var _57: UInt8 = 0
    var _58: UInt8 = 0
    var _59: UInt8 = 0
    var _60: UInt8 = 0
    var _61: UInt8 = 0
    var _62: UInt8 = 0
    var _63: UInt8 = 0
}

foreign func zmq_msg_init(msg: CPointer<ZmqMsg>): Int32

foreign func zmq_msg_init_size(msg: CPointer<ZmqMsg>, size: UIntNative): Int32

foreign func zmq_msg_send(msg: CPointer<ZmqMsg>, s: CPointer<Unit>, flags: Int32): Int32

foreign func zmq_msg_recv(msg: CPointer<ZmqMsg>, s: CPointer<Unit>, flags: Int32): Int32

foreign func zmq_msg_close(msg: CPointer<ZmqMsg>): Int32

foreign func zmq_msg_data(msg: CPointer<ZmqMsg>): CPointer<Unit>

foreign func zmq_msg_size(msg: CPointer<ZmqMsg>): UIntNative
