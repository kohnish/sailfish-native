# sailfish-native

Build and deploy to Sailfish aarch64 without the official SDK toolkit.

## Prep toolchain

1. `./scripts/sysroot.sh`
2. `./scripts/binutils.sh`
3. `./scripts/gcc.sh`

## Test build and deploy

1. `cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=toolchains/aarch64-meego-linux-gnu.cmake -Bbuild`
2. `cmake --build build`
3. `./scripts/package.sh`
4. `./scripts/deploy.sh`
