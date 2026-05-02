## 新增需求

### 需求：libzmq 作为 git submodule
项目应当将 libzmq 源码作为 git submodule 包含在 `vendor/libzmq/` 路径下。

#### 场景：使用 submodules 克隆
- **当** 执行 `git clone --recursive <repo-url>` 时
- **则** libzmq 源码在 `vendor/libzmq/` 路径下可用

### 需求：build.cj 从源码编译 libzmq
项目应当包含 `build.cj` 文件，在 `pre-build` 钩子中编译 libzmq 静态库。

#### 场景：macOS 上 pre-build 编译 libzmq
- **当** 在 macOS 上执行 `cjpm build` 时
- **则** `build.cj` 的 pre-build 钩子在 `vendor/libzmq/build/` 中执行 cmake 和 make
- **且** 在平台特定的输出目录中生成 `libzmq.a`

#### 场景：Linux 上 pre-build 编译 libzmq
- **当** 在 Linux 上执行 `cjpm build` 时
- **则** `build.cj` 的 pre-build 钩子为当前架构编译 libzmq.a

#### 场景：Windows 上 pre-build 编译 libzmq
- **当** 在 Windows 上执行 `cjpm build` 时
- **则** `build.cj` 的 pre-build 钩子使用 MinGW 编译 libzmq

### 需求：cjpm.toml FFI 配置
`cjpm.toml` 应当配置 `[ffi.c]` 以链接编译后的 libzmq 静态库。

#### 场景：macOS FFI 路径已配置
- **当** 在 macOS 上构建时
- **则** `[target.*.ffi.c]` 指向 macOS 构建输出目录

#### 场景：Linux FFI 路径已配置
- **当** 在 Linux 上构建时
- **则** `[target.*.ffi.c]` 指向 Linux 构建输出目录

#### 场景：Windows FFI 路径已配置
- **当** 在 Windows 上构建时
- **则** `[target.*.ffi.c]` 指向 Windows 构建输出目录

### 需求：构建产物被 gitignore
`vendor/build/` 目录应当被添加到 `.gitignore`。

#### 场景：编译产物不被 git 追踪
- **当** libzmq 编译到 `vendor/build/` 中时
- **则** git status 不显示 `vendor/build/` 中的任何文件

### 需求：增量构建跳过重复编译
构建脚本应当检测已有的编译产物并跳过重复编译。

#### 场景：第二次构建跳过 libzmq 编译
- **当** 执行 `cjpm build` 且 `vendor/build/${platform}/libzmq.a` 已存在时
- **则** pre-build 钩子跳过 cmake/make，复用已有的库文件
