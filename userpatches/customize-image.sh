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

misc_root_setup() {
	# Allow user to access the hotend serial device
	echo 'KERNEL=="ttyS2",MODE="0660"' > /etc/udev/rules.d/99-q1-pro.rules
	systemctl mask serial-getty@ttyS2.service
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
	/home/$USER/klippy-env/bin/pip install numpy
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
	export CROWSNEST_UNATTENDED=1
	git clone https://github.com/mainsail-crew/crowsnest
	cd crowsnest
	sudo CROWSNEST_UNATTENDED=1 make install
}

timelapse_setup() {
	cd /home/$USER
	git clone https://github.com/mainsail-crew/moonraker-timelapse.git
	cd /home/$USER/moonraker-timelapse
	yes | make install
}

auto_z_offset_setup() {
	cd /home/$USER
	git clone https://github.com/frap129/qidi_auto_z_offset
	ln -s /home/$USER/qidi_auto_z_offset/auto_z_offset.py /home/$USER/klipper/klippy/extras/auto_z_offset.py
}

config_setup() {
	cd /home/$USER
	git clone https://github.com/frap129/q1-pro-klipper-config
	cd q1-pro-klipper-config
	./install.sh /home/$USER/printer_data/config

	# Setup KAMP
	cd /home/$USER
	git clone https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging.git
	ln -s /home/$USER/Klipper-Adaptive-Meshing-Purging/Configuration /home/$USER/printer_data/config/KAMP
	cp /home/$USER/Klipper-Adaptive-Meshing-Purging/Configuration/KAMP_Settings.cfg /home/$USER/printer_data/config/KAMP_Settings.cfg
}

shaketune_setup() {
	cd /home/$USER
	git clone https://github.com/Frix-x/klippain-shaketune/ klippain_shaketune
	cd klippain_shaketune
	head -n -9 install.sh > tmp-install.sh
	echo "setup_venv
	link_extension" >> tmp-install.sh
	source tmp-install.sh
	rm tmp-install.sh
}

shellcmd_setup() {
	cd /home/$USER
	source $KIAUH_SRCDIR/scripts/gcode_shell_command.sh
	yes n | install_gcode_shell_command
}

kiauh_setup_root() {
	echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
	su $USER -c "/tmp/customize-image.sh"
	sed -i "s/ NOPASSWD://g" /etc/sudoers.d/$USER
}

if [[ "$(whoami)" == "root" ]]; then
	user_setup
	wifi_driver_setup
	misc_root_setup
	kiauh_setup_root
	#expire_passwds
elif [[ "$(whoami)" == "$USER" ]]; then
	kiauh_setup
	prepare_kiauh_env
	klipper_setup
	moonraker_setup
	fluidd_setup
	crowsnest_setup
	timelapse_setup
	auto_z_offset_setup
	config_setup
	shellcmd_setup
	shaketune_setup
fi
