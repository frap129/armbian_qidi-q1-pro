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

kiauh_setup() {
	cd /home/$USER
	git clone https://github.com/dw-0/kiauh
}

prepare_kiauh_env() {
	cd /home/$USER
	KIAUH_SRCDIR="${HOME}/kiauh"
	source $KIAUH_SRCDIR/scripts/ui/general_ui.sh
	source $KIAUH_SRCDIR/scripts/globals.sh
	source $KIAUH_SRCDIR/scripts/utilities.sh
	set_globals
}

klipper_setup() {
	cd /home/$USER
	source $KIAUH_SRCDIR/scripts/klipper.sh
	run_klipper_setup 3 printer
}

moonraker_setup() {
	cd /home/$USER
	source $KIAUH_SRCDIR/scripts/moonraker.sh
	moonraker_setup 1
}

fluidd_setup() {
	cd /home/$USER
	source $KIAUH_SRCDIR/scripts/backup.sh
	source $KIAUH_SRCDIR/scripts/moonraker.sh
	source $KIAUH_SRCDIR/scripts/nginx.sh
	source $KIAUH_SRCDIR/scripts/fluidd.sh
	yes | install_fluidd
}

crowsnest_setup() {
	cd /home/$USER
	sed -i 's/make install/make install CROWSNEST_UNATTENDED=1 CROWSNEST_ADD_CROWSNEST_MOONRAKER=1/g' \
		$KIAUH_SRCDIR/scripts/crowsnest.sh
	source $KIAUH_SRCDIR/scripts/crowsnest.sh
	export CROWSNEST_UNATTENDED=1 CROWSNEST_ADD_CROWSNEST_MOONRAKER=1
	install_crowsnest
	sed -i 's/ CROWSNEST_UNATTENDED=1 CROWSNEST_ADD_CROWSNEST_MOONRAKER=1//g' \
		$KIAUH_SRCDIR/scripts/crowsnest.sh
}

timelapse_setup() {
	cd /home/$USER
	git clone https://github.com/mainsail-crew/moonraker-timelapse.git
	cd ~/moonraker-timelapse
	yes | make install
}

misc_setup() {
	cd /home/$USER
	source $KIAUH_SRCDIR/scripts/gcode_shell_command.sh
	source $KIAUH_SRCDIR/scripts/pretty_gcode.sh
	yes n | install_gcode_shell_command
	yes 7136 | install_pgc_for_klipper
}

kiauh_setup_root() {
	echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
	su $USER -c "/tmp/customize-image.sh"
	sed -i "s/ NOPASSWD://g" /etc/sudoers.d/$USER
}

if [[ "$(whoami)" == "root" ]]; then
	user_setup
	wifi_driver_setup
	kiauh_setup_root
elif [[ "$(whoami)" == "$USER" ]]; then
	kiauh_setup
	prepare_kiauh_env
	klipper_setup
	moonraker_setup
	fluidd_setup
	crowsnest_setup
	timelapse_setup
	misc_setup
fi

#expire_passwds
