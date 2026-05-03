package zmq4cj

import std.core.*

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
    if (src.size > 0) {
        unsafe {
            let handle = acquireArrayRawData<UInt8>(src)
            memcpy(CPointer<Unit>(dst), CPointer<Unit>(handle.pointer), UIntNative(src.size))
            releaseArrayRawData<UInt8>(handle)
        }
    }
}

func copyCPointerToArray(src: CPointer<UInt8>, len: Int64): Array<UInt8> {
    let arr = Array<UInt8>(len, repeat: 0)
    if (len > 0) {
        unsafe {
            let handle = acquireArrayRawData<UInt8>(arr)
            memcpy(CPointer<Unit>(handle.pointer), CPointer<Unit>(src), UIntNative(len))
            releaseArrayRawData<UInt8>(handle)
        }
    }
    arr
}
