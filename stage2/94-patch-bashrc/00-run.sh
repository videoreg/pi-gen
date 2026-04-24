#!/bin/bash -e

BASHRC="${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.bashrc"

cat >> "${BASHRC}" << EOF

# Автоматическая инициализация проекта при SSH сессии
if [ -f /home/${FIRST_USER_NAME}/videoreg/tools/init.sh ]; then
    cd /home/${FIRST_USER_NAME}/videoreg
    source tools/init.sh
fi
EOF

on_chroot << EOF
    chown ${FIRST_USER_NAME}:${FIRST_USER_NAME} /home/${FIRST_USER_NAME}/.bashrc
EOF
