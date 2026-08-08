#!/usr/bin/env bash
set -euxo pipefail

dest="${HOME}/opt/toolchains/sysroots/aarch64-meego-linux-gnu"
target_base="Sailfish_OS-5.1.0.11-Sailfish_SDK_Target-aarch64"
target="${target_base}.tar.7z"
target_tar="${target_base}.tar"
curl -L -O "https://releases.sailfishos.org/sdk/targets/${target}"
7z x "${target}"
mkdir -p "${dest}"
tar --exclude='./usr/share/lipstick/devicelock' --exclude='./etc/pki' --exclude='./dev' -xvf "${target_tar}" -C "${dest}"
rm -f "${target}"
rm -f "${target_tar}"
rm -f "${target_tar}.meta"
echo "Done"
