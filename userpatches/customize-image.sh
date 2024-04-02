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
ARCH=$(dpkg --print-architecture)

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
	git clone https://github.com/lynxlikenation/aic8800.git
	cd aic8800/drivers/aic8800
	sed -i "s|vendor/etc"
	local kernel=$(find /lib/modules/* -type 'd' | head -n 1 | rev | cut -d/ -f1 | rev)
	find . -name Makefile | xargs sed -i "s/\$(shell uname -r)/${kernel}/g"
	make ARCH=arm64 modules install
	cd ../../
	cp -rf ./fw/aic8800DC /lib/firmware/
	cp ./tools/aic.rules /etc/udev/rules.d
}

user_setup
wifi_driver_setup

#expire_passwds
