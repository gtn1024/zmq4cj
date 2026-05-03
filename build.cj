package zmq4cj_build_script

import std.process.*
import std.fs.{exists, Directory}

foreign func system(cmd: CString): Int32

@When[os == "Linux"]
func getPlatformDir(): String {
    "linux"
}

@When[os == "macOS"]
func getPlatformDir(): String {
    "darwin"
}

@When[os == "Windows"]
func getPlatformDir(): String {
    "windows"
}

@When[os == "Linux"]
func getLibName(): String {
    "libzmq.a"
}

@When[os == "macOS"]
func getLibName(): String {
    "libzmq.a"
}

@When[os == "Windows"]
func getLibName(): String {
    "libzmq.a"
}

func runCmd(cmd: String): Int32 {
    unsafe {
        let cCmd = LibC.mallocCString(cmd)
        let rc = system(cCmd)
        LibC.free(cCmd)
        rc
    }
}

func ensureDir(path: String): Unit {
    if (!exists(path)) {
        Directory.create(path, recursive: true)
    }
}

@When[os == "Linux"]
func getCmakeGenerator(): String {
    ""
}

@When[os == "macOS"]
func getCmakeGenerator(): String {
    ""
}

@When[os == "Windows"]
func getCmakeGenerator(): String {
    " -G \"MinGW Makefiles\""
}

@When[os == "Linux"]
func getCmakeExtraFlags(): String {
    " -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC"
}

@When[os == "macOS"]
func getCmakeExtraFlags(): String {
    " -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC"
}

@When[os == "Windows"]
func getCmakeExtraFlags(): String {
    " -DCMAKE_CXX_FLAGS=-static-libstdc++ -static-libgcc"
}

func stagePreBuild(): Int64 {
    let platform = getPlatformDir()
    let libName = getLibName()
    let buildDir = "vendor/build/${platform}"
    let libPath = "${buildDir}/lib/${libName}"

    if (exists(libPath)) {
        return 0
    }

    if (!exists("vendor/libzmq/CMakeLists.txt")) {
        println("ERROR: libzmq submodule not found. Run: git submodule update --init --recursive")
        return 1
    }

    ensureDir(buildDir)

    println("Building libzmq for ${platform}...")

    let cmakeCmd = "cmake -S vendor/libzmq -B ${buildDir} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED=OFF -DBUILD_TESTS=OFF -DZMQ_BUILD_TESTS=OFF${getCmakeGenerator()}${getCmakeExtraFlags()}"
    let cmakeRc = runCmd(cmakeCmd)
    if (cmakeRc != 0) {
        println("ERROR: cmake failed with return code ${cmakeRc}")
        return 1
    }

    let makeRc = runCmd("cmake --build ${buildDir} --config Release")
    if (makeRc != 0) {
        println("ERROR: build failed with return code ${makeRc}")
        return 1
    }

    println("libzmq built successfully: ${libPath}")
    0
}

main(): Int64 {
    match (Process.current.arguments[0]) {
        case "pre-build" => stagePreBuild()
        case _ => 0
    }
}
