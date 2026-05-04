#!/bin/bash

set -ouex pipefail

echo "Installing base operating system software..."

# Copy /ctx/system_files into /
pacman -S --noconfirm \
    rsync

rsync -rvK /ctx/system_files/ /

# Activate the rechunker group fix
chmod +x /usr/bin/rechunker-group-fix
systemctl enable rechunker-group-fix.service

# Downgrade the kernel to 6.19.14 (see issue: https://github.com/bootc-dev/bootc/issues/2174)
# TODO: remove this as soon as the issue is fixed
pacman -Rsn --noconfirm linux
rm -rfv /usr/lib/modules
pacman -U --noconfirm https://archive.archlinux.org/packages/l/linux-zen/linux-zen-6.19.14.zen1-1-x86_64.pkg.tar.zst

echo "Install glibc-locales"
pacman -Sy --noconfirm glibc-locales

echo "Setting the default locale..."
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Install drivers
pacman -S --noconfirm \
    mesa \
    vulkan-radeon \
    vulkan-intel \
    dmidecode \
    amd-ucode \
    intel-ucode \
    thermald

# Install core operating system software
pacman -S --noconfirm \
    networkmanager \
    sudo \
    power-profiles-daemon \
    powertop \
    gamemode \
    fprintd \
    usbutils \
    bluez \
    bluez-utils \
    cups \
    cups-pdf \
    unrar \
    unzip \
    tar \
    man-db \
    inetutils
