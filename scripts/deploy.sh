#!/bin/bash
set -euxo pipefail

SAIL_USER=defaultuser
SAIL_IP=10.0.0.112
RPM_DIR=build/rpmbuild/RPMS/aarch64
RPM_NAME=untitled-0.1-1.aarch64.rpm

scp "${RPM_DIR}/${RPM_NAME}" "${SAIL_USER}@${SAIL_IP}":
ssh "${SAIL_USER}@${SAIL_IP}" sdk-deploy-rpm "${RPM_NAME}"
ssh "${SAIL_USER}@${SAIL_IP}" rm -f "${RPM_NAME}"
