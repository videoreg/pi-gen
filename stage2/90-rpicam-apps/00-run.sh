#!/bin/bash -e

on_chroot << EOF
# Установка build-зависимостей
apt-get update
apt-get install -y \
    git \
    ffmpeg \
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
    libswresample-dev \
    libopencv-dev
EOF

# Клонирование снаружи chroot — SSH-ключи доступны только на хосте сборки
git clone --depth 1 https://github.com/videoreg/rpicam-apps.git "${ROOTFS_DIR}/tmp/rpicam-apps"

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

# Очистка кэша
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
