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

public enum SocketOption {
    | SUBSCRIBE
    | UNSUBSCRIBE
    | RCVMORE
    | LINGER
    | SNDHWM
    | RCVHWM
    | RCVTIMEO
    | SNDTIMEO

    public prop value: Int32 {
        get() {
            match (this) {
                case SUBSCRIBE => 6
                case UNSUBSCRIBE => 7
                case RCVMORE => 13
                case LINGER => 17
                case SNDHWM => 23
                case RCVHWM => 24
                case RCVTIMEO => 27
                case SNDTIMEO => 28
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
