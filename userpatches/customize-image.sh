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
	local groups="netdev,audio,video,disk,tty,users,dialout,plugdev,input"
	useradd -m -s /usr/bin/bash -G ${groups} $USER
	echo "$USER:$PASS" | chpasswd
	echo "root:$PASS" | chpasswd
}

expire_passwds() {
	passwd --expire $USER
	passwd --expire root
}

deb-get_setup() {
	curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
	cp -R /tmp/overlay/pkgs /etc/deb-get/99-local.d
}

wifi_driver_setup() {
	cd /tmp
	git clone https://github.com/lynxlikenation/aic8800.git
	cd aic8800/drivers/aic8800
	local kernel=$(find /lib/modules/* -type 'd' | head -n 1 | rev | cut -d/ -f1 | rev)
	find . -name Makefile | xargs sed -i "s/\$(shell uname -r)/${kernel}/g"
	make ARCH=arm64 modules install
	cd ../../
	cp -rf ./fw/aic8800DC /lib/firmware/
	cp ./tools/aic.rules /etc/udev/rules.d
}

misc_root_setup() {
	# Allow user to access the hotend serial device
	echo 'KERNEL=="ttyS2",MODE="0660"' > /etc/udev/rules.d/99-q1-pro.rules
	systemctl mask serial-getty@ttyS2.service
}

openq1_setup_root() {
	echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
	su $USER -c "/tmp/customize-image.sh"
	sed -i "s/ NOPASSWD://g" /etc/sudoers.d/$USER
}

openq1_setup_user() {
	cd /home/$USER
	git clone https://github.com/frap129/OpenQ1
	cd OpenQ1
	./scripts/install.sh
}

if [[ "$(whoami)" == "root" ]]; then
	user_setup
	deb-get_setup
	wifi_driver_setup
	misc_root_setup
	openq1_setup_root
	#expire_passwds
elif [[ "$(whoami)" == "$USER" ]]; then
	openq1_setup_user
fi
