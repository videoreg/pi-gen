#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/etc/wireguard"
install -m 600 files/wg0.conf "${ROOTFS_DIR}/etc/wireguard/wg0.conf"

on_chroot << EOF
    chown -R ${FIRST_USER_NAME}:${FIRST_USER_NAME} /etc/wireguard/
EOF