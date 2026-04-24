#!/bin/bash -e

install -m 644 files/hwclock-save.service "${ROOTFS_DIR}/etc/systemd/system/hwclock-save.service"

on_chroot << EOF

  raspi-config nonint do_i2c 0

  apt-get install -y util-linux-extra

  systemctl enable hwclock-save.service

EOF