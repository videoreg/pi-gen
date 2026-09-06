#!/bin/bash -e

# Pin libcamera to a build that predates the AGC startup-frame regression.
#
# libcamera commit 93bed4d (2026-08-05, first shipped in 0.7.2+rpt20260807) dropped
#   if (agcConvergenceFrames)
#       agcConvergenceFrames += mistrustCount_;
# from src/ipa/rpi/common/ipa_base.cpp, which shortens the window of frames the pipeline
# handler tags FrameStartup. On ov5647 (mistrustCount_ = 2, no embedded data) that lets
# frames the AGC has not converged on reach the application tagged FrameSuccess, and a
# still capture then saves one of them - daylight photos come out white.
#
# 0.7.1+rpt20260609 is the version that shipped in videoreg image 0.1.1 and demonstrably
# worked on the same camera; 0.7.0+rpt20260205 is older and also predates the commit.
#
# Only the current version is published in the archive index, so the .debs are fetched
# from the pool, which keeps every version.
LIBCAMERA_VERSION="${LIBCAMERA_VERSION:-0.7.0+rpt20260205-1}"
POOL="http://archive.raspberrypi.com/debian/pool/main/libc/libcamera"

DEB_DIR="${ROOTFS_DIR}/tmp/libcamera-pin"
rm -rf "${DEB_DIR}"
mkdir -p "${DEB_DIR}"

# Downloaded outside the chroot, as the chroot has no download tooling at this point.
for pkg in libcamera0.7 libcamera-ipa libcamera-dev; do
    deb="${pkg}_${LIBCAMERA_VERSION}_arm64.deb"
    echo "Fetching ${deb}"
    curl -fL --retry 3 -o "${DEB_DIR}/${deb}" "${POOL}/${deb}"
done

on_chroot << 'EOF'
set -e
cd /tmp/libcamera-pin
apt-get update

# Install the pinned packages' own dependencies first, so dpkg -i has everything. The
# dependency set differs between libcamera versions (0.7.0 needs libegl1, libgles2 and
# libyuv0, which 0.7.2 does not), so read them out of the .debs rather than hardcoding.
deps=$(for f in *.deb; do dpkg-deb -f "$f" Depends; done \
    | tr ',' '\n' \
    | sed 's/(.*)//; s/^[[:space:]]*//; s/[[:space:]]*$//' \
    | grep -v '^libcamera' \
    | grep -v '^$' \
    | sort -u)
apt-get install -y $deps

dpkg -i ./*.deb

# rpicam-apps is built from source into /usr/local (see 90-rpicam-apps) and is invisible
# to apt, so nothing packaged depends on libcamera any more. Without marking it manual,
# the autoremove in 90-rpicam-apps would take it straight back out.
apt-mark manual libcamera0.7 libcamera-ipa
# libcamera-dev is deliberately left unheld: it is a build dependency that
# 90-rpicam-apps purges once the build is done.
apt-mark hold libcamera0.7 libcamera-ipa

apt-get clean
rm -rf /tmp/libcamera-pin
EOF
