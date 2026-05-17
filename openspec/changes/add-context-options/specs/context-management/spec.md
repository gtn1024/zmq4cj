## ADDED Requirements

### Requirement: ZmqContext context option operations
The system SHALL provide `set(option: ContextOption, value: Int32)` and `get(option: ContextOption): Int32` methods on ZmqContext. Both methods SHALL be protected by the existing `mutex` to ensure thread safety with `close()` and `socket()`.

#### Scenario: Set and get are mutex-protected
- **WHEN** one thread calls `ctx.set()` while another calls `ctx.close()`
- **THEN** the operations SHALL be mutually exclusive via `synchronized(mutex)`

#### Scenario: Get after set returns updated value
- **WHEN** calling `ctx.set(ContextOption.MAX_SOCKETS, 512)` then `ctx.get(ContextOption.MAX_SOCKETS)`
- **THEN** the get SHALL return 512
