#!/bin/bash -e

IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"

IMGID="$(dd if="${IMG_FILE}" skip=440 bs=1 count=4 2>/dev/null | xxd -e | cut -f 2 -d' ')"

BOOT_PARTUUID="${IMGID}-01"
ROOT_PARTUUID="${IMGID}-02"
CUSTOM_PARTUUID="${IMGID}-03"

USER_UID=$(awk -F: -v user="$FIRST_USER_NAME" '$1==user {print $3}' "${ROOTFS_DIR}/etc/passwd")

sed -i "s/BOOTDEV/PARTUUID=${BOOT_PARTUUID}/" "${ROOTFS_DIR}/etc/fstab"
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${ROOTFS_DIR}/etc/fstab"
sed -i "s/CUSTOMDEV/PARTUUID=${CUSTOM_PARTUUID}/" "${ROOTFS_DIR}/etc/fstab"

sed -i "s/USER_UID/${USER_UID}/g" "${ROOTFS_DIR}/etc/fstab"
sed -i "s/USER_GID/${USER_UID}/g" "${ROOTFS_DIR}/etc/fstab"

sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${ROOTFS_DIR}/boot/firmware/cmdline.txt"
