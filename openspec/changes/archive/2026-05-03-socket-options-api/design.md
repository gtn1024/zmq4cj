## 背景

`ZmqSocket` 当前暴露了 `setSubscribe(topic: String)` 方法来处理 SUBSCRIBE 选项，但其他 socket 选项（LINGER、RCVTIMEO、SNDHWM 等）没有公开的 get/set API。用户无法通过仓颉代码配置这些参数。

## 目标 / 非目标

**目标：**
- 提供 `setIntOption(option, value)` 用于设置整数类型的 socket 选项
- 提供 `getIntOption(option)` 用于读取整数类型的 socket 选项
- 提供 `setStringOption(option, value)` 用于设置字符串类型的 socket 选项（SUBSCRIBE/UNSUBSCRIBE）
- 保持 `setSubscribe` 不变（内部可复用 `setStringOption`）

**非目标：**
- 不暴露 `CPointer` 级别的原始 `zmq_setsockopt`/`zmq_getsockopt`（保持安全 API）
- 不支持二进制类型的选项（如 CURVE 密钥等，属于安全层，后续工作）
- 不新增 SocketOption 枚举值（当前枚举已足够）

## 设计决策

### 1. 类型化 API 而非泛型 API

**决策**：提供 `setIntOption`、`getIntOption`、`setStringOption` 三个方法，而非一个泛型 `setOption<T>`。

**理由**：仓颉的泛型不支持按类型特化 FFI 调用。`zmq_setsockopt` 的 option_value 是 `const void*`，Int32 和 String 的传参方式完全不同（Int32 用 `inout` 取指针，String 用 `mallocCString`）。分开方法更清晰、类型安全。

### 2. setIntOption 实现

```cangjie
public func setIntOption(option: SocketOption, value: Int32): Unit {
    var val = value
    var size = UIntNative(4)
    unsafe {
        checkResult(zmq_setsockopt(handle, option.value, CPointer<Unit>(CPointer<Int32>(inout val)), size))
    }
}
```

使用 `inout` 栈变量，无需 malloc/free。

### 3. getIntOption 实现

```cangjie
public func getIntOption(option: SocketOption): Int32 {
    var val: Int32 = 0
    var size = UIntNative(4)
    unsafe {
        checkResult(zmq_getsockopt(handle, option.value, CPointer<Unit>(CPointer<Int32>(inout val)), CPointer<UIntNative>(inout size)))
    }
    val
}
```

### 4. setStringOption 实现

```cangjie
public func setStringOption(option: SocketOption, value: String): Unit {
    let cs = stringToCString(value)
    unsafe {
        checkResult(zmq_setsockopt(handle, option.value, CPointer<Unit>(cs), UIntNative(value.size)))
    }
    freeCString(cs)
}
```

### 5. setSubscribe 内部复用

`setSubscribe` 改为调用 `setStringOption(SocketOption.SUBSCRIBE, topic)`，减少重复代码。

## 风险与权衡

- **[选项值范围]** 某些选项可能只接受特定范围的值 → **缓解**：由 libzmq 返回错误，通过 ZmqError 抛出
- **[inout 与 zmq_getsockopt]** `zmq_getsockopt` 的 size 参数是 inout（输入输出），需要传入初始大小 → 已处理
