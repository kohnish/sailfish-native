#!/usr/bin/env bash

set -euo pipefail

NAME="untitled"
VERSION="0.1"
RELEASE="1"
TARGET_ARCH="aarch64"
SUMMARY="My Sailfish OS Application"
LICENSE="GPLv3"
URL="https://example.org/"
DESCRIPTION="My Sailfish OS Application."

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CMAKE_BUILD_DIR="${PROJECT_DIR}/build"
PKGROOT="${CMAKE_BUILD_DIR}/pkgroot/usr"
cmake --install "${CMAKE_BUILD_DIR}" --prefix "${PKGROOT}"

RPMBUILD_ROOT="${CMAKE_BUILD_DIR}/rpmbuild"
SPECS_DIR="${RPMBUILD_ROOT}/SPECS"
BUILD_DIR="${RPMBUILD_ROOT}/BUILD"
RPMS_DIR="${RPMBUILD_ROOT}/RPMS"
SRPMS_DIR="${RPMBUILD_ROOT}/SRPMS"

SPEC="${SPECS_DIR}/${NAME}.spec"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

command -v rpmbuild >/dev/null 2>&1 ||
    die "rpmbuild not found"

command -v rpm >/dev/null 2>&1 ||
    die "rpm not found"

rm -rf "${RPMBUILD_ROOT}"

mkdir -p \
    "${SPECS_DIR}" \
    "${BUILD_DIR}" \
    "${RPMS_DIR}" \
    "${SRPMS_DIR}"

cat > "${SPEC}" <<EOF
Name:           ${NAME}
Version:        ${VERSION}
Release:        ${RELEASE}
Summary:        ${SUMMARY}
License:        ${LICENSE}
URL:            ${URL}

Requires:       sailfishsilica-qt5

%description
${DESCRIPTION}

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr
cp -a "${PKGROOT}" %{buildroot}

%files
%defattr(-,root,root,-)
/usr/*
EOF

echo
echo "Building RPM..."
echo

rpmbuild \
    -bb \
    --target="${TARGET_ARCH}" \
    --define "_topdir ${RPMBUILD_ROOT}" \
    --define "_builddir ${BUILD_DIR}" \
    --define "_rpmdir ${RPMS_DIR}" \
    --define "_srcrpmdir ${SRPMS_DIR}" \
    "${SPEC}"

RPM="$(find "${RPMS_DIR}" -type f -name '*.rpm' | head -1)"

[ -n "${RPM}" ] || die "RPM was not produced"

echo
echo "============================================================"
echo "RPM build completed"
echo "============================================================"
echo

echo "RPM:"
echo "  ${RPM}"

echo
echo "Architecture:"
rpm -qp --qf '%{ARCH}\n' "${RPM}"

echo
echo "Package contents:"
rpm -qpl "${RPM}"
echo
echo "Done."
