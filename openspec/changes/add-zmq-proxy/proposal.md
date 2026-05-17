## Why

zmq_proxy 是 ZeroMQ 最常用的高级 API 之一，用于构建消息代理（如 PUB/SUB 代理、REQ/REP 负载均衡器）。它是构建分布式系统的核心组件，几乎所有主流 ZeroMQ 绑定（libzmq、pyzmq、czmq）都提供此功能。目前 zmq4cj 缺少此 API，用户无法在仓颉中构建代理模式。

## What Changes

- 在 FFI 层 (`zmq_ffi.cj`) 添加 `zmq_proxy` 和 `zmq_proxy_steerable` 的 `foreign func` 声明
- 新增 `ZmqProxy` 公共类，提供静态方法 `start(frontend, backend, capture?)` 和 `startSteerable(frontend, backend, capture?, control)`
- 添加相应的单元测试验证代理功能

## Capabilities

### New Capabilities
- `proxy`: 封装 zmq_proxy 和 zmq_proxy_steerable，提供仓颉语言的 ZeroMQ 代理 API

### Modified Capabilities

## Impact

- `src/zmq_ffi.cj`: 新增 2 个 foreign func 声明
- `src/zmq_proxy.cj`: 新文件，ZmqProxy 公共类
- `src/zmq_socket.cj`: 无修改（ZmqProxy 接收 ZmqSocket 参数，提取底层 C 指针）
- `src/zmq_test.cj`: 新增代理相关测试
- 公共 API 新增 ZmqProxy 类，不影响现有 API
