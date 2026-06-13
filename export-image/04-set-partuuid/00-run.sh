#!/bin/bash -e

# Honor the custom image name written by stage2/91-videoreg (via img_name),
# exactly like prerun.sh and 05-finalise do. Without this, IMG_FILE points at a
# non-existent "${IMG_FILENAME}${IMG_SUFFIX}.img", dd reads nothing, and the
# disk identifier below comes out empty -> "PARTUUID=-02" in an unbootable image.
if [ -f "${WORK_DIR}/img_name" ]; then
	IMG_FILENAME=$(cat "${WORK_DIR}/img_name")
	IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}.img"
else
	IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"
fi

IMGID="$(dd if="${IMG_FILE}" skip=440 bs=1 count=4 2>/dev/null | xxd -e | cut -f 2 -d' ')"

# Guard against a silent failure here: if `xxd` is missing from the build
# environment (or dd produced nothing) the pipeline above yields an empty
# string, `cut` still exits 0, and we would bake "PARTUUID=-02" into fstab and
# cmdline.txt -> an unbootable image (update-initramfs warns "Couldn't identify
# type of root file system 'PARTUUID=-02'"). Fail loudly instead. A genuine
# empty MBR disk signature reads back as "00000000", which is equally unusable.
if [ -z "${IMGID}" ] || [ "${IMGID}" = "00000000" ]; then
	echo "ERROR: could not read MBR disk identifier from ${IMG_FILE} (got '${IMGID}'); is 'xxd' installed?" >&2
	exit 1
fi

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
