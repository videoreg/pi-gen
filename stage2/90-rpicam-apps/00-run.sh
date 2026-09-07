#!/bin/bash -e

# Tag of the videoreg/rpicam-apps fork to build. Pin it so images are
# reproducible: an unpinned clone takes whatever develop points at on the
# build day, which is how the 2026-08-28 image ended up pairing a v1.11.1
# fork with libcamera 0.7.2.
RPICAM_APPS_REF="v1.11.1-vrg1"

on_chroot << EOF
# Install build dependencies
apt-get update
apt-get install -y \
    git \
    ffmpeg \
    meson \
    cmake \
    ninja-build \
    libepoxy-dev \
    libjpeg-dev \
    libtiff5-dev \
    libpng-dev \
    libboost-program-options-dev \
    libdrm-dev \
    libexif-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev \
    libopencv-dev
EOF

# Cloned outside the chroot: SSH keys are only available on the build host
git clone --depth 1 --branch "${RPICAM_APPS_REF}" \
  https://github.com/videoreg/rpicam-apps.git "${ROOTFS_DIR}/tmp/rpicam-apps"

on_chroot << EOF
# Build rpicam-apps
cd /tmp/rpicam-apps

meson setup --wipe build \
  -Denable_libav=enabled \
  -Denable_drm=disabled \
  -Denable_egl=disabled \
  -Denable_qt=disabled \
  -Denable_opencv=enabled \
  -Denable_tflite=disabled \
  -Denable_hailo=disabled

ninja -C build
ninja -C build install
ldconfig

# Clean up the sources
cd /tmp
rm -rf rpicam-apps

# Remove the build dependencies
apt-get remove --purge -y \
    meson \
    cmake \
    ninja-build \
    libcamera-dev \
    libepoxy-dev \
    libjpeg-dev \
    libtiff5-dev \
    libpng-dev \
    libboost-program-options-dev \
    libdrm-dev \
    libexif-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev

# Autoremove what is no longer needed (this also takes out libopencv-dev and its runtime libraries)
apt-get autoremove -y

# Reinstall the OpenCV runtime libraries: rpicam-apps links against them but is
# installed by ninja, so APT has no record of the dependency.
# apt-cache pkgnames resolves package names dynamically, with no hardcoded version suffix.
apt-get install -y libopencv-dev

# The same applies to Boost.ProgramOptions. Its runtime used to survive incidentally
# because the stock rpicam-apps-core depended on it; that package is no longer installed
# (see 89-libcamera), so the autoremove above takes the library out and no rpicam-* binary
# can start.
BOOST_PO=\$(apt-cache pkgnames libboost-program-options \
    | grep -E '^libboost-program-options[0-9]' | sort -V | tail -1)
if [ -z "\$BOOST_PO" ]; then
    echo "ERROR: cannot resolve the Boost.ProgramOptions runtime package"
    exit 1
fi
apt-get install -y "\$BOOST_PO"

# What ninja installs is invisible to APT, so nothing catches a missing runtime
# dependency until the first run on a device. Check it here and fail the build rather
# than ship an image whose camera does not work.
for f in /usr/local/bin/rpicam-* \
         /usr/local/lib/aarch64-linux-gnu/librpicam_app.so.1 \
         /usr/local/lib/aarch64-linux-gnu/rpicam-apps-postproc/*.so \
         /usr/local/lib/aarch64-linux-gnu/rpicam-apps-encoder/*.so; do
    [ -e "\$f" ] || continue
    if ldd "\$f" 2>/dev/null | grep -q 'not found'; then
        echo "ERROR: unresolved shared libraries in \$f"
        ldd "\$f" | grep 'not found'
        exit 1
    fi
done

# Clean the APT cache
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
