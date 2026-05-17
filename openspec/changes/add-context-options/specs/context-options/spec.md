## ADDED Requirements

### Requirement: ContextOption enum
The system SHALL provide a `ContextOption` enum with members: IO_THREADS, MAX_SOCKETS, SOCKET_LIMIT, THREAD_PRIORITY, THREAD_SCHED_POLICY, MAX_MSGSZ, MSG_T_SIZE, THREAD_NAME_PREFIX. Each member SHALL map to the corresponding libzmq constant value.

#### Scenario: Enum values match libzmq constants
- **WHEN** accessing `ContextOption.IO_THREADS.value`
- **THEN** the value SHALL be 1

### Requirement: ZmqContext set option
The system SHALL provide `set(option: ContextOption, value: Int32)` on ZmqContext that calls `zmq_ctx_set` with the given option and value. The method SHALL throw `ZmqError` if the context is closed or if the underlying call fails.

#### Scenario: Set IO_THREADS before socket creation
- **WHEN** calling `ctx.set(ContextOption.IO_THREADS, 2)` before creating any socket
- **THEN** the call SHALL succeed (return without error)

#### Scenario: Set option on closed context throws ZmqError
- **WHEN** calling `ctx.set(ContextOption.IO_THREADS, 2)` after `ctx.close()`
- **THEN** the call SHALL throw `ZmqError`

### Requirement: ZmqContext get option
The system SHALL provide `get(option: ContextOption): Int32` on ZmqContext that calls `zmq_ctx_get` with the given option and returns the result. The method SHALL throw `ZmqError` if the context is closed or if the underlying call fails.

#### Scenario: Get IO_THREADS returns configured value
- **WHEN** calling `ctx.get(ContextOption.IO_THREADS)` after setting it to 2
- **THEN** the method SHALL return 2

#### Scenario: Get option on closed context throws ZmqError
- **WHEN** calling `ctx.get(ContextOption.IO_THREADS)` after `ctx.close()`
- **THEN** the call SHALL throw `ZmqError`

#### Scenario: Get SOCKET_LIMIT returns system limit
- **WHEN** calling `ctx.get(ContextOption.SOCKET_LIMIT)` on a new context
- **THEN** the method SHALL return a positive Int32 value (the system max socket limit)
