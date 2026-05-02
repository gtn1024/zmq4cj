## 修改需求

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
