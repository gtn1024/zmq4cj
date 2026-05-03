## 新增需求

### 需求：memcpy FFI 声明
系统应当提供 `foreign func memcpy` 声明，绑定 C 标准库的 `memcpy` 函数。

#### 场景：memcpy 在 C 指针之间拷贝字节
- **当** 使用有效的 C 指针和字节数调用 `memcpy(dest, src, n)` 时
- **则** 恰好 `n` 个字节从 `src` 拷贝到 `dest`，并返回 `dest`

### 需求：从 Array 批量拷贝到 CPointer
系统应当提供使用 `memcpy` 将字节从 `Array<UInt8>` 拷贝到 `CPointer<UInt8>` 的函数，替代逐字节循环。

#### 场景：Array 数据通过一次操作拷贝到 C 指针
- **当** 将 65536 个元素的 `Array<UInt8>` 拷贝到 `CPointer<UInt8>` 时
- **则** 通过 `memcpy` 正确拷贝全部 65536 字节

#### 场景：空数组不产生拷贝
- **当** 将空的 `Array<UInt8>` 拷贝到 `CPointer<UInt8>` 时
- **则** `memcpy` 以 size=0 调用，不写入任何字节

### 需求：从 CPointer 批量拷贝到 Array
系统应当提供使用 `memcpy` 将字节从 `CPointer<UInt8>` 拷贝到 `Array<UInt8>` 的函数，替代逐字节循环。

#### 场景：C 指针数据通过一次操作拷贝到 Array
- **当** 将 65536 字节从 `CPointer<UInt8>` 拷贝到新的 `Array<UInt8>` 时
- **则** 通过 `memcpy` 正确拷贝全部 65536 字节

#### 场景：零长度不产生拷贝
- **当** 从 `CPointer<UInt8>` 拷贝 0 字节时
- **则** `memcpy` 以 size=0 调用，结果为空数组
