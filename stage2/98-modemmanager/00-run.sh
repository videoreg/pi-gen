#!/bin/bash -e

DROPIN_DIR="${ROOTFS_DIR}/etc/systemd/system/ModemManager.service.d"
mkdir -p "${DROPIN_DIR}"

cat > "${DROPIN_DIR}/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/ModemManager --debug
LogLevelMax=info
TimeoutStopSec=3s
EOF
