#!/bin/bash -e

install -m 600 files/wifi.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/wifi.nmconnection"
install -m 600 files/ap.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/ap.nmconnection"
install -m 600 files/modem.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/modem.nmconnection"

WPA_ESSID=${WPA_ESSID:-haritonovo2024}
WPA_PASSWORD=${WPA_PASSWORD:-iloveitmo}

# wifi.nmconnection
sed -i "s/WIFI_SSID/${WPA_ESSID}/g" "${ROOTFS_DIR}/etc/NetworkManager/system-connections/wifi.nmconnection"
sed -i "s/WIFI_PASSWORD/${WPA_PASSWORD}/g" "${ROOTFS_DIR}/etc/NetworkManager/system-connections/wifi.nmconnection"
sed -i "s/WIFI_COUNTRY/${WPA_COUNTRY}/g" "${ROOTFS_DIR}/etc/NetworkManager/system-connections/wifi.nmconnection"