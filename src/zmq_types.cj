package zmq

public enum SocketType {
    | PAIR
    | PUB
    | SUB
    | REQ
    | REP
    | DEALER
    | ROUTER
    | PULL
    | PUSH
    | XPUB
    | XSUB
    | STREAM

    public prop value: Int32 {
        get() {
            match (this) {
                case PAIR => 0
                case PUB => 1
                case SUB => 2
                case REQ => 3
                case REP => 4
                case DEALER => 5
                case ROUTER => 6
                case PULL => 7
                case PUSH => 8
                case XPUB => 9
                case XSUB => 10
                case STREAM => 11
            }
        }
    }
}

public enum ContextOption {
    | IO_THREADS
    | MAX_SOCKETS
    | SOCKET_LIMIT
    | THREAD_PRIORITY
    | THREAD_SCHED_POLICY
    | MAX_MSGSZ
    | MSG_T_SIZE
    | THREAD_NAME_PREFIX

    public prop value: Int32 {
        get() {
            match (this) {
                case IO_THREADS => 1
                case MAX_SOCKETS => 2
                case SOCKET_LIMIT => 3
                case THREAD_PRIORITY => 3
                case THREAD_SCHED_POLICY => 4
                case MAX_MSGSZ => 5
                case MSG_T_SIZE => 6
                case THREAD_NAME_PREFIX => 9
            }
        }
    }
}

public enum SocketOption {
    | SUBSCRIBE
    | UNSUBSCRIBE
    | RCVMORE
    | AFFINITY
    | IDENTITY
    | RATE
    | RECOVERY_IVL
    | SNDBUF
    | RCVBUF
    | LINGER
    | RECONNECT_IVL
    | BACKLOG
    | RECONNECT_IVL_MAX
    | MAXMSGSIZE
    | SNDHWM
    | RCVHWM
    | RCVTIMEO
    | SNDTIMEO
    | ROUTER_MANDATORY
    | TCP_KEEPALIVE
    | TCP_KEEPALIVE_IDLE
    | TCP_KEEPALIVE_INTVL
    | PROBE_ROUTER
    | REQ_CORRELATE
    | REQ_RELAXED
    | IPV4ONLY
    | HANDSHAKE_IVL
    | HEARTBEAT_IVL
    | HEARTBEAT_TIMEOUT
    | HEARTBEAT_TTL
    | CONNECT_TIMEOUT
    | ROUTING_ID

    public prop value: Int32 {
        get() {
            match (this) {
                case SUBSCRIBE => 6
                case UNSUBSCRIBE => 7
                case RCVMORE => 13
                case AFFINITY => 4
                case IDENTITY => 5
                case RATE => 8
                case RECOVERY_IVL => 9
                case SNDBUF => 11
                case RCVBUF => 12
                case LINGER => 17
                case RECONNECT_IVL => 18
                case BACKLOG => 19
                case RECONNECT_IVL_MAX => 21
                case MAXMSGSIZE => 22
                case SNDHWM => 23
                case RCVHWM => 24
                case RCVTIMEO => 27
                case SNDTIMEO => 28
                case ROUTER_MANDATORY => 33
                case TCP_KEEPALIVE => 34
                case TCP_KEEPALIVE_IDLE => 36
                case TCP_KEEPALIVE_INTVL => 37
                case PROBE_ROUTER => 51
                case REQ_CORRELATE => 52
                case REQ_RELAXED => 53
                case IPV4ONLY => 31
                case HANDSHAKE_IVL => 66
                case HEARTBEAT_IVL => 75
                case HEARTBEAT_TIMEOUT => 77
                case HEARTBEAT_TTL => 76
                case CONNECT_TIMEOUT => 79
                case ROUTING_ID => 5
            }
        }
    }
}

public enum SendRecvFlags {
    | DONTWAIT
    | SNDMORE

    public prop value: Int32 {
        get() {
            match (this) {
                case DONTWAIT => 1
                case SNDMORE => 2
            }
        }
    }
}

public enum PollEvent {
    | POLLIN
    | POLLOUT
    | POLLERR

    public prop value: Int16 {
        get() {
            match (this) {
                case POLLIN => 1
                case POLLOUT => 2
                case POLLERR => 4
            }
        }
    }
}
