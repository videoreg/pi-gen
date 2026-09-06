#!/bin/bash -e

# Tag of the videoreg/rpicam-apps fork to build. Pin it so images are
# reproducible: an unpinned clone takes whatever develop points at on the
# build day, which is how the 2026-08-28 image ended up pairing a v1.11.1
# fork with libcamera 0.7.2.
RPICAM_APPS_REF="v1.11.1-vrg1"

on_chroot << EOF
# Установка build-зависимостей
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

# Клонирование снаружи chroot — SSH-ключи доступны только на хосте сборки
git clone --depth 1 --branch "${RPICAM_APPS_REF}" \
  https://github.com/videoreg/rpicam-apps.git "${ROOTFS_DIR}/tmp/rpicam-apps"

on_chroot << EOF
# Сборка rpicam-apps
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

# Очистка исходников
cd /tmp
rm -rf rpicam-apps

# Удаление build-зависимостей
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

# Автоудаление ненужных зависимостей (в том числе удалит libopencv-dev и рантайм-либы)
apt-get autoremove -y

# Переустановить рантайм-либы OpenCV: rpicam-apps слинкован с ними,
# но установлен через ninja — APT не знает об этой зависимости.
# apt-cache pkgnames находит пакеты динамически без хардкода суффикса версии.
apt-get install -y libopencv-dev

# То же самое для Boost.ProgramOptions. Раньше рантайм выживал попутно, потому что от
# него зависел стоковый rpicam-apps-core; он больше не ставится (см. 89-libcamera), и
# autoremove выше уносит библиотеку, после чего ни один rpicam-* не стартует.
BOOST_PO=\$(apt-cache pkgnames libboost-program-options \
    | grep -E '^libboost-program-options[0-9]' | sort -V | tail -1)
if [ -z "\$BOOST_PO" ]; then
    echo "ERROR: cannot resolve the Boost.ProgramOptions runtime package"
    exit 1
fi
apt-get install -y "\$BOOST_PO"

# Собранное через ninja невидимо для APT, поэтому недостающую рантайм-зависимость
# ничто не поймает до первого запуска на устройстве. Проверяем здесь и валим сборку,
# чтобы не выпускать образ с неработающей камерой.
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

# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
