#!/usr/bin/env bash
set -Eeuo pipefail

PS4='+ ${BASH_SOURCE}:${LINENO}: '
set -x

# ======================================================================
# Configuration
# ======================================================================

TARGET="aarch64-meego-linux-gnu"
GCC_VERSION="14.4.0"

ROOT="$HOME/opt/toolchains"

PREFIX="$ROOT/$TARGET"
SYSROOT="$ROOT/sysroots/$TARGET"

SRC_DIR="$ROOT/src"
BUILD_ROOT="$ROOT/build"

SOURCE_DIR="$SRC_DIR/gcc-${GCC_VERSION}"
BUILD_DIR="$BUILD_ROOT/gcc-${GCC_VERSION}"

TARBALL="gcc-${GCC_VERSION}.tar.gz"

GCC_URL="https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/${TARBALL}"

CONFIG_LOG="$BUILD_DIR/configure.log"
BUILD_LOG="$BUILD_DIR/build.log"
INSTALL_LOG="$BUILD_DIR/install.log"

# ======================================================================
# Error handling
# ======================================================================

on_error()
{
    status=$?

    set +x

    echo
    echo "============================================================"
    echo "GCC BUILD FAILED"
    echo "============================================================"
    echo
    echo "Exit status: $status"
    echo
    echo "Source:"
    echo "  $SOURCE_DIR"
    echo
    echo "Build:"
    echo "  $BUILD_DIR"
    echo
    echo "Configure log:"
    echo "  $CONFIG_LOG"
    echo
    echo "Build log:"
    echo "  $BUILD_LOG"
    echo

    if [[ -f "$BUILD_LOG" ]]; then
        echo "============================================================"
        echo "LIKELY ERRORS"
        echo "============================================================"

        grep -n -E \
            'error:|Error [0-9]+|collect2:|undefined reference|cannot find|No such file|failed' \
            "$BUILD_LOG" \
            | head -100 \
            || true

        echo
        echo "============================================================"
        echo "LAST 150 LINES"
        echo "============================================================"

        tail -150 "$BUILD_LOG" || true
    fi

    exit "$status"
}

trap on_error ERR

# ======================================================================
# Basic information
# ======================================================================

echo
echo "============================================================"
echo "GCC ${GCC_VERSION}"
echo "============================================================"
echo
echo "Target : $TARGET"
echo "Prefix : $PREFIX"
echo "Sysroot: $SYSROOT"
echo "Source : $SOURCE_DIR"
echo "Build  : $BUILD_DIR"
echo
echo "Download:"
echo "  $GCC_URL"
echo

# ======================================================================
# Host tools
# ======================================================================

for tool in gcc g++ make tar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: required host tool not found: $tool"
        exit 1
    fi
done

echo
echo "============================================================"
echo "HOST COMPILER"
echo "============================================================"
echo

gcc --version | head -1
echo
gcc -dumpmachine
echo
g++ --version | head -1

# ======================================================================
# Prevent environment variables from contaminating the build
# ======================================================================

unset CC
unset CXX
unset CPP

unset AR
unset AS
unset LD
unset NM
unset RANLIB
unset STRIP
unset OBJCOPY
unset OBJDUMP
unset READELF

unset CFLAGS
unset CXXFLAGS
unset CPPFLAGS
unset LDFLAGS
unset LIBS

# ======================================================================
# Check sysroot
# ======================================================================

echo
echo "============================================================"
echo "CHECKING SYSROOT"
echo "============================================================"

if [[ ! -d "$SYSROOT" ]]; then
    echo "error: sysroot does not exist:"
    echo "  $SYSROOT"
    exit 1
fi

REQUIRED_SYSROOT_FILES=(
    "$SYSROOT/usr/include/features.h"
    "$SYSROOT/usr/lib64/crt1.o"
    "$SYSROOT/usr/lib64/crti.o"
    "$SYSROOT/usr/lib64/crtn.o"
    "$SYSROOT/lib64/libc.so.6"
    "$SYSROOT/lib/ld-linux-aarch64.so.1"
)

for file in "${REQUIRED_SYSROOT_FILES[@]}"; do
    if [[ ! -e "$file" ]]; then
        echo "error: required sysroot file missing:"
        echo "  $file"
        exit 1
    fi
done

echo "Sysroot OK."

# ======================================================================
# Check binutils
# ======================================================================

AS="$PREFIX/bin/$TARGET-as"
LD="$PREFIX/bin/$TARGET-ld"

echo
echo "============================================================"
echo "CHECKING BINUTILS"
echo "============================================================"

if [[ ! -x "$AS" ]]; then
    echo "error: target assembler not found:"
    echo "  $AS"
    echo
    echo "Build binutils first."
    exit 1
fi

if [[ ! -x "$LD" ]]; then
    echo "error: target linker not found:"
    echo "  $LD"
    echo
    echo "Build binutils first."
    exit 1
fi

echo
echo "Assembler:"
"$AS" --version | head -1

echo
echo "Linker:"
"$LD" --version | head -1

# ======================================================================
# Download GCC
# ======================================================================

mkdir -p "$SRC_DIR"

cd "$SRC_DIR"

if [[ ! -f "$TARBALL" ]]; then

    echo
    echo "============================================================"
    echo "DOWNLOADING GCC ${GCC_VERSION}"
    echo "============================================================"

    wget \
        "$GCC_URL" \
        -O "$TARBALL"
fi

# ======================================================================
# Verify tarball
# ======================================================================

echo
echo "============================================================"
echo "CHECKING GCC TARBALL"
echo "============================================================"

if ! tar -tf "$TARBALL" >/dev/null 2>&1; then
    echo "error: invalid GCC tarball:"
    echo "  $SRC_DIR/$TARBALL"
    echo
    echo "File information:"
    file "$TARBALL" || true
    exit 1
fi

echo "GCC tarball OK."

# ======================================================================
# Extract GCC
# ======================================================================

if [[ ! -d "$SOURCE_DIR" ]]; then

    echo
    echo "============================================================"
    echo "EXTRACTING GCC"
    echo "============================================================"

    tar -xf "$TARBALL"
fi

if [[ ! -f "$SOURCE_DIR/configure" ]]; then
    echo "error: GCC source tree is invalid:"
    echo "  $SOURCE_DIR"
    exit 1
fi

# ======================================================================
# GCC prerequisites
#
# GMP, MPFR, MPC and ISL are HOST build dependencies.
#
# They do NOT use the target sysroot.
# ======================================================================

cd "$SOURCE_DIR"

if [[ ! -d gmp || ! -d mpfr || ! -d mpc || ! -d isl ]]; then

    echo
    echo "============================================================"
    echo "DOWNLOADING GCC PREREQUISITES"
    echo "============================================================"

    ./contrib/download_prerequisites
else
    echo
    echo "GCC prerequisites already present."
fi

# ======================================================================
# ALWAYS start with a completely clean build directory
# ======================================================================

echo
echo "============================================================"
echo "CLEANING BUILD DIRECTORY"
echo "============================================================"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo
echo "Fresh build directory:"
echo "  $BUILD_DIR"

# ======================================================================
# Configure
# ======================================================================

cd "$BUILD_DIR"

echo
echo "============================================================"
echo "CONFIGURING GCC"
echo "============================================================"

"$SOURCE_DIR/configure" \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-sysroot="$SYSROOT" \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-nls \
    --disable-werror \
    2>&1 | tee "$CONFIG_LOG"

# ======================================================================
# Build
#
# Start with one job so failures are easy to diagnose.
# Once this succeeds, -j$(nproc) can be used for subsequent builds.
# ======================================================================

echo
echo "============================================================"
echo "BUILDING GCC"
echo "============================================================"
echo
echo "make -j6 V=1"
echo

rm -f "$BUILD_LOG"

set +e

make -j6 V=1 2>&1 | tee "$BUILD_LOG"

MAKE_STATUS=${PIPESTATUS[0]}

set -e

if [[ "$MAKE_STATUS" -ne 0 ]]; then

    echo
    echo "============================================================"
    echo "MAKE FAILED"
    echo "============================================================"
    echo
    echo "Exit status: $MAKE_STATUS"
    echo
    echo "Build log:"
    echo "  $BUILD_LOG"

    echo
    echo "============================================================"
    echo "FIRST ERRORS"
    echo "============================================================"

    grep -n -E \
        'error:|Error [0-9]+|collect2:|undefined reference|cannot find|No such file|failed' \
        "$BUILD_LOG" \
        | head -100 \
        || true

    echo
    echo "============================================================"
    echo "LAST 150 LINES"
    echo "============================================================"

    tail -150 "$BUILD_LOG"

    exit "$MAKE_STATUS"
fi

# ======================================================================
# Install
# ======================================================================

echo
echo "============================================================"
echo "INSTALLING GCC"
echo "============================================================"

rm -f "$INSTALL_LOG"

make install 2>&1 | tee "$INSTALL_LOG"

# ======================================================================
# Verify installation
# ======================================================================

GCC="$PREFIX/bin/$TARGET-gcc"
GXX="$PREFIX/bin/$TARGET-g++"

echo
echo "============================================================"
echo "VERIFYING INSTALLATION"
echo "============================================================"

if [[ ! -x "$GCC" ]]; then
    echo "error: GCC was not installed:"
    echo "  $GCC"
    exit 1
fi

if [[ ! -x "$GXX" ]]; then
    echo "error: G++ was not installed:"
    echo "  $GXX"
    exit 1
fi

echo
echo "gcc:"
"$GCC" --version | head -3

echo
echo "g++:"
"$GXX" --version | head -3

echo
echo "Target:"
"$GCC" -dumpmachine

echo
echo "Sysroot:"
"$GCC" -print-sysroot

echo
echo "libgcc:"
"$GCC" -print-libgcc-file-name

echo
echo "libstdc++:"
"$GXX" -print-file-name=libstdc++.so

echo
echo "============================================================"
echo "GCC ${GCC_VERSION} BUILD AND INSTALL COMPLETE"
echo "============================================================"
