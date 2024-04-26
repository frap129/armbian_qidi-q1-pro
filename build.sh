#!/usr/bin/env bash

./compile.sh \
	BOARD=qidi-q1 \
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
	$@
