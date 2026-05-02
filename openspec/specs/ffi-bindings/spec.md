## 新增需求

### 需求：上下文管理函数的 FFI 声明
系统应当通过 `foreign func` 声明以下 libzmq C 函数：
- `zmq_ctx_new(): CPointer<Unit>`
- `zmq_ctx_term(ctx: CPointer<Unit>): Int32`
- `zmq_ctx_set(ctx: CPointer<Unit>, option: Int32, value: Int32): Int32`
- `zmq_ctx_get(ctx: CPointer<Unit>, option: Int32): Int32`

#### 场景：上下文函数声明编译成功
- **当** 执行 `cjpm build` 时
- **则** 所有上下文管理的 foreign func 声明无编译错误

### 需求：Socket 管理函数的 FFI 声明
系统应当声明以下 libzmq C 函数：
- `zmq_socket(ctx: CPointer<Unit>, type_: Int32): CPointer<Unit>`
- `zmq_close(socket: CPointer<Unit>): Int32`
- `zmq_setsockopt(socket: CPointer<Unit>, option: Int32, value: CPointer<Unit>, len: UIntNative): Int32`
- `zmq_getsockopt(socket: CPointer<Unit>, option: Int32, value: CPointer<Unit>, len: CPointer<Unit>): Int32`

#### 场景：Socket 函数声明编译成功
- **当** 执行 `cjpm build` 时
- **则** 所有 Socket 管理的 foreign func 声明无编译错误

### 需求：连接函数的 FFI 声明
系统应当声明：
- `zmq_bind(socket: CPointer<Unit>, addr: CString): Int32`
- `zmq_connect(socket: CPointer<Unit>, addr: CString): Int32`
- `zmq_unbind(socket: CPointer<Unit>, addr: CString): Int32`
- `zmq_disconnect(socket: CPointer<Unit>, addr: CString): Int32`

#### 场景：连接函数声明编译成功
- **当** 执行 `cjpm build` 时
- **则** 所有连接相关的 foreign func 声明无编译错误

### 需求：消息收发函数的 FFI 声明
系统应当声明：
- `zmq_send(socket: CPointer<Unit>, buf: CPointer<Unit>, len: UIntNative, flags: Int32): Int32`
- `zmq_recv(socket: CPointer<Unit>, buf: CPointer<Unit>, len: UIntNative, flags: Int32): Int32`

#### 场景：消息函数声明编译成功
- **当** 执行 `cjpm build` 时
- **则** 所有 send/recv 的 foreign func 声明无编译错误

### 需求：错误处理函数的 FFI 声明
系统应当声明：
- `zmq_errno(): Int32`
- `zmq_strerror(errno: Int32): CString`

#### 场景：错误函数声明编译成功
- **当** 执行 `cjpm build` 时
- **则** 所有错误处理的 foreign func 声明无编译错误

### 需求：FFI 声明使用正确的类型映射
所有 `foreign func` 声明应当使用以下类型映射约定：
- C `void*` → `CPointer<Unit>`
- C `size_t` → `UIntNative`
- C `int` → `Int32`
- C `const char*` → `CString`
- C `char*`（输出缓冲区）→ `CPointer<UInt8>`

#### 场景：类型映射与 C 头文件定义一致
- **当** 将 foreign func 签名与 zmq.h 对比时
- **则** 每个参数和返回类型按映射约定与 C 类型匹配

### 需求：zmq_msg_send FFI 声明
系统应当新增 `zmq_msg_send` 的 `foreign func` 声明：
- `zmq_msg_send(msg: CPointer<ZmqMsg>, s: CPointer<Unit>, flags: Int32): Int32`

#### 场景：zmq_msg_send 声明编译成功
- **当** 执行 `cjpm build` 时
- **则** `zmq_msg_send` 的 foreign func 声明无编译错误

#### 场景：zmq_msg_send 类型映射与 zmq.h 一致
- **当** 与 C 声明 `int zmq_msg_send(zmq_msg_t *msg, void *s, int flags)` 对比时
- **则** 参数类型映射为 `CPointer<ZmqMsg>`, `CPointer<Unit>`, `Int32`，返回 `Int32`

### 需求：zmq_msg_init_size FFI 声明
系统应当新增 `zmq_msg_init_size` 的 `foreign func` 声明：
- `zmq_msg_init_size(msg: CPointer<ZmqMsg>, size: UIntNative): Int32`

#### 场景：zmq_msg_init_size 声明编译成功
- **当** 执行 `cjpm build` 时
- **则** `zmq_msg_init_size` 的 foreign func 声明无编译错误

#### 场景：zmq_msg_init_size 类型映射与 zmq.h 一致
- **当** 与 C 声明 `int zmq_msg_init_size(zmq_msg_t *msg, size_t size)` 对比时
- **则** 参数类型映射为 `CPointer<ZmqMsg>`, `UIntNative`，返回 `Int32`
