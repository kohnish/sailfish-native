set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# ----------------------------------------------------------------------
# Toolchain
# ----------------------------------------------------------------------

set(TOOLCHAIN_ROOT
    "$ENV{HOME}/opt/toolchains/aarch64-meego-linux-gnu"
)

set(TARGET_TRIPLE
    "aarch64-meego-linux-gnu"
)

set(CMAKE_C_COMPILER
    "${TOOLCHAIN_ROOT}/bin/${TARGET_TRIPLE}-gcc"
)

set(CMAKE_CXX_COMPILER
    "${TOOLCHAIN_ROOT}/bin/${TARGET_TRIPLE}-g++"
)

set(CMAKE_ASM_COMPILER
    "${TOOLCHAIN_ROOT}/bin/${TARGET_TRIPLE}-gcc"
)

# ----------------------------------------------------------------------
# Sailfish OS sysroot
# ----------------------------------------------------------------------

set(CMAKE_SYSROOT
    "$ENV{HOME}/opt/toolchains/sysroots/${TARGET_TRIPLE}"
)

# ----------------------------------------------------------------------
# CMake target search paths
# ----------------------------------------------------------------------

set(CMAKE_FIND_ROOT_PATH
    "${CMAKE_SYSROOT}"
    "${TOOLCHAIN_ROOT}"
)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# ----------------------------------------------------------------------
# Don't try to execute AArch64 binaries during configure tests.
# ----------------------------------------------------------------------

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----------------------------------------------------------------------
# Compiler target
# ----------------------------------------------------------------------

set(CMAKE_C_COMPILER_TARGET
    "${TARGET_TRIPLE}"
)

set(CMAKE_CXX_COMPILER_TARGET
    "${TARGET_TRIPLE}"
)

# ----------------------------------------------------------------------
# pkg-config
#
# Use the host pkg-config executable, but make it operate against the
# Sailfish target sysroot.
# ----------------------------------------------------------------------

find_program(PKG_CONFIG_EXECUTABLE
    NAMES pkg-config
    REQUIRED
)

set(ENV{PKG_CONFIG_SYSROOT_DIR}
    "${CMAKE_SYSROOT}"
)

set(ENV{PKG_CONFIG_LIBDIR}
    "${CMAKE_SYSROOT}/usr/lib64/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig"
)

set(ENV{PKG_CONFIG_PATH}
    ""
)

# ----------------------------------------------------------------------
# C++
# ----------------------------------------------------------------------

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
