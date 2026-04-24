#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/etc/systemd/journald.conf.d/"
install -m 644 files/90-persistent-storage.conf "${ROOTFS_DIR}/etc/systemd/journald.conf.d/90-persistent-storage.conf"

mkdir -p "${ROOTFS_DIR}/var/log/journal"

on_chroot << EOF
chown root:systemd-journal /var/log/journal
chmod 2755 /var/log/journal
EOF
