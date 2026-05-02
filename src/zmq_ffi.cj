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
