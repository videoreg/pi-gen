#!/bin/bash -e

VIDEOREG_DIR="/home/${FIRST_USER_NAME}/videoreg"

echo "Start install videoreg to ${VIDEOREG_DIR}"

on_chroot << EOF
  mkdir -m 755 "${VIDEOREG_DIR}"
  chown ${FIRST_USER_NAME}:${FIRST_USER_NAME} "${VIDEOREG_DIR}"
EOF

git clone --depth 1 https://github.com/videoreg/pi-videoreg.git "${ROOTFS_DIR}/${VIDEOREG_DIR}"

VIDEOREG_VERSION_FILE="${ROOTFS_DIR}/${VIDEOREG_DIR}/VERSION"
if [ -f "${VIDEOREG_VERSION_FILE}" ]; then
  VIDEOREG_VERSION=$(cat "${VIDEOREG_VERSION_FILE}" | tr -d '[:space:]')
  echo "videoreg-${VIDEOREG_VERSION}" > "${WORK_DIR}/img_name"
  echo "PiVideoreg version: ${VIDEOREG_VERSION}"
else
  echo "WARNING: VERSION file not found in pi-videoreg repo"
fi

on_chroot << EOF
  chown -R ${FIRST_USER_NAME}:${FIRST_USER_NAME} "${VIDEOREG_DIR}"

  cd "${VIDEOREG_DIR}"

  source ./tools/init.sh

  vrg-install \
    --user $FIRST_USER_NAME \
    --group $FIRST_USER_NAME \
    --storage-path "/mnt/data/videoreg" \
    --yes
EOF

echo "Videoreg installed successfully!"