#!/bin/bash

# arguments: $RELEASE $FAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script
#
# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

RELEASE=$1
FAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4
ARCH=`dpkg --print-architecture`

USER="mks"
PASS="mks"

user_setup() {
    useradd -m $USER
    echo "$USER:$PASS" | chpasswd

    echo "root:$PASS" | chpasswd
}

expire_passwds() {
    passwd --expire $USER
    passwd --expire root
}

wifi_driver_setup() {
	cd /tmp
    #git clone https://github.com/OpenIPC/aic8800
    git clone https://github.com/Thedemon007/aic8800
    cd aic8800/aic8800
    #sed -i 's|stddef.h|linux/stddef.h|g' aic_load_fw/aicbluetooth_cmds.c
    local kernel=$(find /lib/modules/* -type 'd' | head -n 1 | rev | cut -d/ -f1 | rev)
    #cp /usr/lib/gcc/aarch64-linux-gnu/12/include/stddef.h /lib/modules/${kernel}/build/include
	make CONFIG_PLATFORM_UBUNTU=n KVER=${kernel} KDIR=/lib/modules/${kernel}/build PWD=$(pwd) \
		MODDESTDIR=/lib/modules/${kernel}/kernel/drivers/net/wireless/aic8800 ARCH=arm64 modules install
	echo "aic8800_fdrv" > /etc/modules-load.d/wifi.conf
	cd ..
	cp -rf ./fw/aic8800DC /lib/firmware/
	cp ./tools/aic.rules /etc/udev/rules.d
}

user_setup
wifi_driver_setup

#expire_passwds
