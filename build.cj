package zmq_build_script

import std.process.*
import std.env.{getVariable, getWorkingDirectory}
import std.fs.{exists, Directory, copy, removeIfExists, File}
import std.collection.ArrayList

foreign func system(cmd: CString): Int32

// cjpm compiles this build script with --cfg=target=<target triple>. The Windows
// branch is selected whenever the build target is x86_64-w64-mingw32, whether that
// is a native Windows build (os == Windows) or a cross-build from Linux/macOS.
@When[target == "x86_64-w64-mingw32"]
func isWindowsTarget(): Bool {
    true
}

@When[target != "x86_64-w64-mingw32"]
func isWindowsTarget(): Bool {
    false
}

// True only when running ON Windows (native). Used to skip the cross-build mirror:
// a native build resolves ffi.c directly (host == target), so no mirror/marker needed.
@When[os == "Windows"]
func isWindowsHost(): Bool {
    true
}

@When[os != "Windows"]
func isWindowsHost(): Bool {
    false
}

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

func runCmd(cmd: String): Int32 {
    unsafe {
        let cCmd = LibC.mallocCString(cmd)
        let rc = system(cCmd)
        LibC.free(cCmd)
        rc
    }
}

// Marker dropped into a non-Windows host lib dir when a cross-build mirrors a PE
// libzmq_vendor.a there. Lets a later native build detect the foreign-format artifact.
let CROSS_MIRROR_MARKER: String = ".cross-mirror"

func ensureDir(path: String): Unit {
    if (!exists(path)) {
        Directory.create(path, recursive: true)
    }
}

// zig binary: $ZIG env var if set, else "zig" (expected on PATH).
func zigBin(): String {
    match (getVariable("ZIG")) {
        case Some(s) => s
        case None => "zig"
    }
}

// llvm-ar from Cangjie's bundled LLVM ($CANGJIE_HOME/third_party/llvm/bin).
// Forward-slash the path: on Windows CANGJIE_HOME may contain backslashes, and cmake
// writes CMAKE_AR into its cache .cmake files where "\t" / "\l" would be escape errors.
@When[os == "Windows"]
func llvmArBin(): String {
    let home = (getVariable("CANGJIE_HOME") ?? "").replace("\\", "/")
    if (!home.isEmpty()) {
        let candidate = "${home}/third_party/llvm/bin/llvm-ar.exe"
        if (exists(candidate)) {
            return candidate
        }
    }
    "llvm-ar"
}

@When[os != "Windows"]
func llvmArBin(): String {
    let home = getVariable("CANGJIE_HOME") ?? ""
    if (!home.isEmpty()) {
        let candidate = "${home}/third_party/llvm/bin/llvm-ar"
        if (exists(candidate)) {
            return candidate
        }
    }
    "llvm-ar"
}

// --- Windows build helpers (native + cross). zig produces a libc++ ABI libzmq
// matching Cangjie's llvm-mingw runtime; system MinGW (libstdc++) would not link. ---

let WIN_TARGET: String = "x86_64-windows-gnu"

// Wrapper script extension + content, platform-aware. cmake needs a single
// executable for CMAKE_C/CXX_COMPILER, but zig takes a "cc"/"c++" subcommand and
// extra flags — so we generate a tiny launcher.

@When[os == "Windows"]
func wrapperExt(): String {
    ".bat"
}

@When[os != "Windows"]
func wrapperExt(): String {
    ".sh"
}

@When[os == "Windows"]
func zigCcWrapper(zig: String): String {
"""
@echo off
"${zig}" cc -target ${WIN_TARGET} -O2 -fno-sanitize=undefined %*
"""
}

@When[os != "Windows"]
func zigCcWrapper(zig: String): String {
"""
#!/bin/sh
exec "${zig}" cc -target ${WIN_TARGET} -O2 -fno-sanitize=undefined "$@"
"""
}

@When[os == "Windows"]
func zigCxxWrapper(zig: String): String {
"""
@echo off
"${zig}" c++ -target ${WIN_TARGET} -O2 -fno-sanitize=undefined %*
"""
}

@When[os != "Windows"]
func zigCxxWrapper(zig: String): String {
"""
#!/bin/sh
exec "${zig}" c++ -target ${WIN_TARGET} -O2 -fno-sanitize=undefined "$@"
"""
}

// windres shim: zig has no windres/llvm-rc, and version.rc resources are meaningless
// in a static .a. The shim copies a prebuilt empty COFF object to the output path.
// cmake probes the RC compiler during detection (no/odd args); the shim must stay
// silent then — print nothing, exit 0.
@When[os == "Windows"]
func windresShim(): String {
"""
@echo off
set "OUT="
:loop
if "%~1"=="" goto done
set "OUT=%~1"
shift
goto loop
:done
if not "%OUT%"=="" copy "%~dp0empty.obj" "%OUT%" >nul 2>nul
"""
}

@When[os != "Windows"]
func windresShim(): String {
"""
#!/bin/sh
out=""; seen=0; last=""
for a in "$@"; do
  if [ "$seen" = "1" ]; then out="$a"; seen=0; continue; fi
  case "$a" in -o) seen=1 ;; -*) ;; *) last="$a" ;; esac
done
[ -z "$out" ] && out="$last"
[ -n "$out" ] && cp "$(dirname "$0")/empty.obj" "$out" 2>/dev/null
exit 0
"""
}

// No-op ranlib: llvm-ar creates the symbol index itself (rcs), so ranlib is redundant.
// Crucially, GNU ranlib would rewrite the archive index into a form Cangjie's ld.lld
// mis-reads (symbols come out undefined), so it must NOT run.
@When[os == "Windows"]
func noopShim(): String {
"""
@echo off
exit 0
"""
}

@When[os != "Windows"]
func noopShim(): String {
"""
#!/bin/sh
exit 0
"""
}

// .sh wrappers need the exec bit on Unix; .bat needs nothing on Windows.
@When[os != "Windows"]
func makeExecutable(path: String): Unit {
    runCmd("chmod +x \"${path}\"")
}

@When[os == "Windows"]
func makeExecutable(path: String): Unit {
    ()
}

let IPHLPAPI_STUB_C: String = "#include <stddef.h>\n" +
    "unsigned long GetAdaptersAddresses(unsigned long Family, unsigned long Flags,\n" +
    "    void *Reserved, void *AdapterAddresses, size_t *SizePointer) {\n" +
    "    (void)Family; (void)Flags; (void)Reserved; (void)AdapterAddresses;\n" +
    "    if (SizePointer) *SizePointer = 0;\n" +
    "    return 50UL;\n}\n" +
    "unsigned int if_nametoindex(const char *ifname) { (void)ifname; return 0; }\n" +
    "char *if_indextoname(unsigned int ifindex, char *ifname) { (void)ifindex; (void)ifname; return 0; }\n"

// Drop version.rc from the MINGW static-library target. PE version resources are
// meaningless in a static .a, and our windres shim (zig has no real windres) can pass
// cmake's enable_language(RC) probe but not the real compile rule. With version.rc gone
// no RC compile is ever scheduled (cmake's Windows-GNU module still enable_language(RC)'s
// during project() — harmless). Idempotent: no-op if already patched.
// We rebuild the file line-by-line: blank the ${CMAKE_CURRENT_BINARY_DIR}/version.rc token
// on the line that immediately follows the static target's ${zmq-pkgconfig} line. Robust
// to exact indentation (no fragile whitespace counting).
func patchLibzmqCmake(): Unit {
    let p = "vendor/libzmq/CMakeLists.txt"
    if (!exists(p)) {
        return
    }
    // Git for Windows defaults to core.autocrlf=true, so the checked-out CMakeLists.txt
    // has CRLF line endings. Normalize to LF first so split/endsWith below match reliably.
    let original = String.fromUtf8(File.readFrom(p)).replace("\r\n", "\n").replace("\r", "\n")
    let lines = original.split("\n")
    var changed = false
    var sawPkgconfig = false
    var out = ArrayList<String>()
    for (line in lines) {
        let l = line.toString()
        if (sawPkgconfig && l.contains("version.rc)")) {
            // Drop the version.rc token but KEEP the closing paren so add_library(...) still parses.
            out.add(l.replace("\${CMAKE_CURRENT_BINARY_DIR}/version.rc)", ")"))
            changed = true
        } else {
            out.add(l)
        }
        sawPkgconfig = l.endsWith("\${zmq-pkgconfig}")
    }
    if (changed) {
        File.writeTo(p, String.join(out.toArray(), delimiter: "\n").toArray())
        println("Patched vendor/libzmq/CMakeLists.txt (dropped version.rc from static target)")
    }
}

func stageWindowsBuild(): Int64 {
    let winLibDir = "vendor/build/windows/lib"
    let toolsDir = "vendor/build/windows/_tools"
    let buildDir = "vendor/build/windows/_crossbuild"
    let vendorLibPath = "${winLibDir}/libzmq_vendor.a"

    if (!exists("vendor/libzmq/CMakeLists.txt")) {
        if (exists(".git")) {
            println("Initializing libzmq submodule...")
            let rc = runCmd("git submodule update --init --recursive")
            if (rc != 0) {
                println("ERROR: git submodule init failed with return code ${rc}")
                return 1
            }
        }
    }

    if (!exists(vendorLibPath)) {
        let zig = zigBin()
        let llvmAr = llvmArBin()
        ensureDir(winLibDir)
        ensureDir(toolsDir)
        // cmake requires CMAKE_*_COMPILER as absolute paths. getWorkingDirectory() on
        // Windows returns backslashes (D:\a\...); cmake writes CMAKE_RC_COMPILER into
        // CMakeRCCompiler.cmake verbatim, and "\a" / "\U" / "\P" in that path then fail
        // to parse ("Invalid character escape"). Normalize to forward slashes everywhere
        // — cmake, Ninja and the wrappers all accept them on Windows.
        let toolsAbs = "${getWorkingDirectory().toString()}/${toolsDir}".replace("\\", "/")

        let ccWrap = "${toolsAbs}/zig-cc${wrapperExt()}"
        let cxxWrap = "${toolsAbs}/zig-cxx${wrapperExt()}"
        let rcWrap = "${toolsAbs}/windres-shim${wrapperExt()}"
        let ranlibWrap = "${toolsAbs}/noop${wrapperExt()}"
        File.writeTo(ccWrap, zigCcWrapper(zig).toArray())
        File.writeTo(cxxWrap, zigCxxWrapper(zig).toArray())
        File.writeTo(rcWrap, windresShim().toArray())
        File.writeTo(ranlibWrap, noopShim().toArray())
        makeExecutable(ccWrap)
        makeExecutable(cxxWrap)
        makeExecutable(rcWrap)
        makeExecutable(ranlibWrap)

        // empty.c → empty.obj (a valid COFF object the windres shim copies for version.rc)
        File.writeTo("${toolsDir}/empty.c", "/* empty translation unit */\n".toArray())
        // Use execute() (argv, no shell) so paths/quotes work uniformly on Unix and Windows.
        let emptyRc = execute(zig, ["cc", "-target", WIN_TARGET, "-c", "${toolsAbs}/empty.c", "-o", "${toolsAbs}/empty.obj"])
        if (emptyRc != 0) {
            println("ERROR: failed to build empty.obj (zig rc=${emptyRc})")
            return 1
        }

        File.writeTo("${toolsDir}/iphlpapi_stub.c", IPHLPAPI_STUB_C.toArray())

        patchLibzmqCmake()

        // CMAKE_AR=llvm-ar makes cmake emit an ld.lld-compatible archive directly,
        // so no GNU-ar → llvm-ar re-packaging step is needed.
        let cmakeArgs = ["-S", "vendor/libzmq", "-B", buildDir, "-G", "Ninja",
            "-DCMAKE_SYSTEM_NAME=Windows", "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
            "-DCMAKE_C_COMPILER=${ccWrap}", "-DCMAKE_CXX_COMPILER=${cxxWrap}",
            "-DCMAKE_RC_COMPILER=${rcWrap}", "-DCMAKE_AR=${llvmAr}", "-DCMAKE_RANLIB=${ranlibWrap}",
            "-DZMQ_WIN32_WINNT=0x0A00", "-DZMQ_HAVE_IPC=OFF",
            "-DBUILD_SHARED=OFF", "-DBUILD_TESTS=OFF", "-DZMQ_BUILD_TESTS=OFF", "-DWITH_TLS=OFF",
            // cmake 4.x removed support for cmake_minimum_required < 3.5; libzmq pins 2.8.12.
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
            "-DCMAKE_BUILD_TYPE=Release"]
        println("Configuring libzmq for ${WIN_TARGET} via zig...")
        let cmakeRc = execute("cmake", cmakeArgs)
        if (cmakeRc != 0) {
            println("ERROR: cmake failed with return code ${cmakeRc}")
            return 1
        }
        let buildRc = execute("cmake", ["--build", buildDir, "--config", "Release"])
        if (buildRc != 0) {
            println("ERROR: build failed with return code ${buildRc}")
            return 1
        }

        copy("${buildDir}/lib/libzmq.a", to: vendorLibPath, overwrite: true)

        // iphlpapi stub (Cangjie's bundled mingw is minimal; only these 3 symbols are referenced)
        let stubRc = execute(zig, ["cc", "-target", WIN_TARGET, "-O2", "-c", "${toolsDir}/iphlpapi_stub.c", "-o", "${toolsDir}/iphlpapi_stub.obj"])
        if (stubRc != 0) {
            println("ERROR: iphlpapi stub compile failed (rc=${stubRc})")
            return 1
        }
        let arRc = execute(llvmAr, ["rcs", "${winLibDir}/libiphlpapi.a", "${toolsDir}/iphlpapi_stub.obj"])
        if (arRc != 0) {
            println("ERROR: libiphlpapi.a archive failed (rc=${arRc})")
            return 1
        }
    }

    // Cross-build (host != Windows): cjpm resolves ffi.c via the HOST target's path
    // (vendor/build/<host>/lib), not the --target's. Mirror the PE libzmq_vendor.a there
    // (with a marker) so the cross-link finds the right format and a later native build
    // can detect/rebuild. Native Windows resolves ffi.c directly — no mirror.
    if (!isWindowsHost()) {
        let hostLibDir = "vendor/build/${getPlatformDir()}/lib"
        ensureDir(hostLibDir)
        copy(vendorLibPath, to: "${hostLibDir}/libzmq_vendor.a", overwrite: true)
        File.writeTo("${hostLibDir}/${CROSS_MIRROR_MARKER}", "".toArray())
        println("libzmq built for Windows (PE mirrored to ${hostLibDir})")
    } else {
        println("libzmq built for Windows")
    }
    0
}

@When[os == "Linux"]
func getCmakeExtraFlags(): String {
    " -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DWITH_TLS=OFF"
}

@When[os == "macOS"]
func getCmakeExtraFlags(): String {
    " -DCMAKE_C_FLAGS=-fPIC -DCMAKE_CXX_FLAGS=-fPIC -DWITH_TLS=OFF"
}

// Unused on Windows (stageNativeBuild is not invoked there), but stageNativeBuild's
// body still references this when compiled on Windows, so a Windows variant must exist.
@When[os == "Windows"]
func getCmakeExtraFlags(): String {
    ""
}

// Native (Linux/macOS) build: cmake + make with the system toolchain.
func stageNativeBuild(): Int64 {
    let platform = getPlatformDir()
    let buildDir = "vendor/build/${platform}"
    let libPath = "${buildDir}/lib/libzmq.a"
    let libDir = "${buildDir}/lib"
    let vendorLibPath = "${libDir}/libzmq_vendor.a"
    let crossMarker = "${libDir}/${CROSS_MIRROR_MARKER}"

    if (exists(crossMarker)) {
        println("Detected cross-build mirror in ${libDir}; rebuilding native libzmq...")
        removeIfExists(vendorLibPath)
        removeIfExists(crossMarker)
    } else if (exists(vendorLibPath)) {
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

    let cmakeCmd = "cmake -S vendor/libzmq -B ${buildDir} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED=OFF -DBUILD_TESTS=OFF -DZMQ_BUILD_TESTS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5${getCmakeExtraFlags()}"
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

    copy(libPath, to: vendorLibPath, overwrite: true)

    println("libzmq built successfully")
    0
}

func stagePreBuild(): Int64 {
    if (isWindowsTarget()) {
        return stageWindowsBuild()
    }
    stageNativeBuild()
}

main(): Int64 {
    let arg = Process.current.arguments[0]
    // cjpm invokes the script as "pre-<command>" (pre-build, pre-test, pre-install).
    if (arg.startsWith("pre-")) {
        return stagePreBuild()
    }
    0
}
