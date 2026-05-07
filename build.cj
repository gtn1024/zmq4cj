package zmq_build_script

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
func getCmakeExtraFlags(): String {
    " -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DWITH_TLS=OFF"
}

@When[os == "macOS"]
func getCmakeExtraFlags(): String {
    " -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DWITH_TLS=OFF"
}

func stagePreBuild(): Int64 {
    let platform = getPlatformDir()
    let buildDir = "vendor/build/${platform}"
    let libPath = "${buildDir}/lib/libzmq.a"
    let vendorLibPath = "${buildDir}/lib/libzmq_vendor.a"

    if (exists(vendorLibPath)) {
        return 0
    }

    if (!exists("vendor/libzmq/CMakeLists.txt")) {
        if (exists(".git")) {
            println("Initializing libzmq submodule...")
            let rc = runCmd("git submodule update --init --recursive")
            if (rc != 0) {
                println("ERROR: git submodule init failed with return code ${rc}")
                return 1
            }
        }
        if (!exists("vendor/libzmq/CMakeLists.txt")) {
            println("ERROR: libzmq source not found. If building from git, run: git submodule update --init --recursive")
            return 1
        }
    }

    ensureDir(buildDir)

    println("Building libzmq for ${platform}...")

    let cmakeCmd = "cmake -S vendor/libzmq -B ${buildDir} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED=OFF -DBUILD_TESTS=OFF -DZMQ_BUILD_TESTS=OFF${getCmakeExtraFlags()}"
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

    let cpRc = runCmd("cp ${libPath} ${vendorLibPath}")
    if (cpRc != 0) {
        println("ERROR: failed to create ${vendorLibPath}")
        return 1
    }

    println("libzmq built successfully")
    0
}

main(): Int64 {
    match (Process.current.arguments[0]) {
        case "pre-build" => stagePreBuild()
        case _ => 0
    }
}
