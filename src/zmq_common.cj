package zmq4cj

func stringToCString(s: String): CString {
    unsafe {
        LibC.mallocCString(s)
    }
}

func freeCString(cs: CString): Unit {
    unsafe {
        LibC.free(cs)
    }
}

func copyArrayToCPointer(src: Array<UInt8>, dst: CPointer<UInt8>): Unit {
    unsafe {
        var i: Int64 = 0
        while (i < src.size) {
            (dst + i).write(src[i])
            i++
        }
    }
}

func copyCPointerToArray(src: CPointer<UInt8>, len: Int64): Array<UInt8> {
    let arr = Array<UInt8>(len, repeat: 0)
    unsafe {
        var i: Int64 = 0
        while (i < len) {
            arr[i] = (src + i).read()
            i++
        }
    }
    arr
}
