#!/usr/bin/env bash

PACKAGES="eject virtualenv python3-dev python3-serial libffi-dev build-essential
    libncurses-dev libusb-dev avrdude gcc-avr binutils-avr avr-libc stm32flash
    libnewlib-arm-none-eabi gcc-arm-none-eabi binutils-arm-none-eabi libusb-1.0
    pkg-config dfu-util libjpeg62-turbo-dev libsodium-dev libopenjp2-7 liblmdb-dev
    nginx crudini libbsd-dev libevent-2.1-7 libevent-dev libevent-extra-2.1-7
    libevent-openssl-2.1-7 libevent-pthreads-2.1-7 libjpeg-dev libmd-dev libv4l-0
    libv4l2rds0 libv4lconvert0 python3-iniparse v4l-utils ffmpeg libopenblas-dev
    libatlas-base-dev python3.11-venv"

# This needs to be set based on the number of packages
REFS=""
for PKG in $PACKAGES; do REFS+="build:compile.sh:0 "; done

./compile.sh \
	BOARD=mkspi \
	BRANCH=current \
	RELEASE=bookworm \
	BSPFREEZE=yes \
	BUILD_DESKTOP=no \
	BUILD_MINIMAL=no \
	KERNEL_CONFIGURE=no \
	INCLUDE_HOME_DIR=yes \
	INSTALL_HEADERS=yes \
	BUILD_KSRC=yes \
	INSTALL_KSRC=yes \
	EXTRA_PACKAGES_IMAGE="$PACKAGES" \
	EXTRA_PACKAGES_IMAGE_REFS="$REFS"
