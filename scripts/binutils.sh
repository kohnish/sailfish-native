#!/usr/bin/env bash
set -euo pipefail

TARGET="aarch64-meego-linux-gnu"
BINUTILS_VERSION="2.45.1"

TOOLCHAIN_ROOT="$HOME/opt/toolchains"
PREFIX="$TOOLCHAIN_ROOT/$TARGET"
SYSROOT="$TOOLCHAIN_ROOT/sysroots/$TARGET"
SRC_DIR="$TOOLCHAIN_ROOT/src"
BUILD_DIR="$TOOLCHAIN_ROOT/build/binutils"

TARBALL="binutils-${BINUTILS_VERSION}.tar.gz"
URL="https://sourceware.org/pub/binutils/releases/${TARBALL}"
SOURCE_DIR="$SRC_DIR/binutils-${BINUTILS_VERSION}"

echo "==> Target:  $TARGET"
echo "==> Prefix:  $PREFIX"
echo "==> Sysroot: $SYSROOT"
echo

# ----------------------------------------------------------------------
# Check prerequisites
# ----------------------------------------------------------------------

command -v wget >/dev/null || {
    echo "error: wget is required" >&2
    exit 1
}

command -v make >/dev/null || {
    echo "error: make is required" >&2
    exit 1
}

# ----------------------------------------------------------------------
# Check sysroot
# ----------------------------------------------------------------------

if [[ ! -d "$SYSROOT" ]]; then
    echo "error: sysroot does not exist:"
    echo "       $SYSROOT"
    exit 1
fi

if [[ ! -f "$SYSROOT/usr/include/features.h" ]]; then
    echo "warning: glibc headers not found at:"
    echo "         $SYSROOT/usr/include/features.h"
fi

# ----------------------------------------------------------------------
# Download
# ----------------------------------------------------------------------

mkdir -p "$SRC_DIR"

cd "$SRC_DIR"

if [[ ! -f "$TARBALL" ]]; then
    echo "==> Downloading Binutils $BINUTILS_VERSION"
    wget "$URL"
else
    echo "==> Using existing $TARBALL"
fi

# ----------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "==> Extracting $TARBALL"
    tar -xf "$TARBALL"
else
    echo "==> Source already extracted"
fi

# ----------------------------------------------------------------------
# Configure
# ----------------------------------------------------------------------

echo "==> Preparing build directory"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

echo "==> Configuring Binutils"

"$SOURCE_DIR/configure" \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-sysroot="$SYSROOT" \
    --disable-nls \
    --disable-werror \
    --disable-gprofng

# ----------------------------------------------------------------------
# Build
# ----------------------------------------------------------------------

echo "==> Building Binutils"

make -j"$(nproc)"

# ----------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------

echo "==> Installing Binutils"

make install

# ----------------------------------------------------------------------
# Verify
# ----------------------------------------------------------------------

AS="$PREFIX/bin/$TARGET-as"
LD="$PREFIX/bin/$TARGET-ld"

echo
echo "==> Installed:"
echo "    $AS"
echo "    $LD"
echo

if [[ ! -x "$AS" ]]; then
    echo "error: assembler was not installed" >&2
    exit 1
fi

if [[ ! -x "$LD" ]]; then
    echo "error: linker was not installed" >&2
    exit 1
fi

echo "==> Assembler version:"
"$AS" --version | head -1

echo
echo "==> Linker version:"
"$LD" --version | head -1

echo
echo "==> Linker sysroot:"
"$LD" --verbose | grep 'SEARCH_DIR' || true

echo
echo "==> Binutils build completed successfully."
