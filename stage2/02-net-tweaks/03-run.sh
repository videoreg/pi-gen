#!/bin/bash -e

DROPIN_DIR="${ROOTFS_DIR}/etc/systemd/system/NetworkManager.service.d"
mkdir -p "${DROPIN_DIR}"

cat > "${DROPIN_DIR}/override.conf" << 'EOF'
[Service]
TimeoutStopSec=3s
EOF
