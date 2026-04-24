#!/bin/bash -e

on_chroot <<- EOF

  raspi-config disable resize2fs_once

  if [ -f /etc/init.d/resize2fs_once ]; then
      mv /etc/init.d/resize2fs_once /etc/init.d/resize2fs_once.disabled
  fi

  set +e
  sudo systemctl disable resize2fs_once
  set -e

EOF