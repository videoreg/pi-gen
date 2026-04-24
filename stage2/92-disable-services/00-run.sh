#!/bin/bash -e

on_chroot << EOF
  # systemctl disable cloud-config.service
  # systemctl disable cloud-init-local.service
  # systemctl disable cloud-init-main.service
  # systemctl disable cloud-init-network.service
  # systemctl disable cloud-init-hotplugd.socket

  apt-get purge -y cloud-init
  apt-get autoremove -y

  rm -rf /etc/cloud/
  rm -rf /var/lib/cloud/

  systemctl disable avahi-daemon
  systemctl disable apt-daily.timer
  systemctl disable apt-daily-upgrade.timer
  systemctl disable rpi-eeprom-update.service
  systemctl disable userconfig.service
  systemctl disable console-setup.service
  systemctl disable man-db.timer
  systemctl disable dpkg-db-backup.timer
  systemctl disable udisks2.service
  systemctl disable e2scrub_all.timer
EOF
