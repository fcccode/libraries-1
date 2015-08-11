#!/bin/bash

CMD=$0
MODULE=$1
ARCH=$2

#default is x86
case $# in
0)
	MODULE=all;
	ARCH=x86;;
1)
	ARCH=x86;;
esac

#add supported platform to here
PLATFORM="[x86|pi|android]"

#basic libraries
BASIC_LIBS="libgzf liblog libgevent libworkq libdict libsort librbtree"
NETWORK_LIBS="libskt libstun libptcp libp2p librpc"

usage()
{
	echo "==== usage ===="
	echo "$CMD <module> [platform]"
	echo "<module>: library to compile or all library, must needed"
	echo "[platform]: x86, raspberrypi or android, default is x86, optional"
	echo ""
	echo "./build.sh all $PLATFORM"
	echo "./build.sh basic_libs $PLATFORM"
	echo "./build.sh network_libs $PLATFORM"
	echo ""
	echo "basic libraries (must):"
	for item in $BASIC_LIBS; do
		echo "$CMD $item $PLATFORM";
	done
	echo ""
	echo "network libraries (optional):"
	for item in $NETWORK_LIBS; do
		echo "$CMD $item $PLATFORM";
	done
	exit
}

config_x86()
{
	CROSS_PREFIX=
}

config_pi()
{
	CROSS_PREFIX=arm-linux-gnueabihf-
}

config_android()
{
	CROSS_PREFIX=arm-linux-androideabi-
}

config_common()
{
	STRIP=${CROSS_PREFIX}strip
	LIBS_DIR=`pwd`
	OUTPUT=${LIBS_DIR}/output
}

config_arch()
{
	case $ARCH in
		"pi")
		config_pi;;
	"android")
		config_android;;
	"x86")
		config_x86;;
	*)
		usage;;
	esac
}

check_output()
{
	if [ ! -d "${OUTPUT}" ]; then
		mkdir -p ${OUTPUT}/include
		mkdir -p ${OUTPUT}/lib
	fi
}

build_module()
{
	MODULE_DIR=${LIBS_DIR}/$1
	ACTION=$2
	if [ ! -d "${MODULE_DIR}" ]; then
		echo "==== build ${MODULE} failed!"
		echo "     dir \"${MODULE_DIR}\" is not exist"
		return
	fi
	cd ${LIBS_DIR}/${MODULE}/

	case $ACTION in
	"clean")
		make clean > /dev/null
		echo "==== clean ${MODULE} done."
		return
		;;
	"install")
		MAKE="make ARCH=${ARCH}"
		${MAKE} install > /dev/null
		if [ $? -ne 0 ]; then
			echo "==== install ${MODULE} failed"
			return;
		else
			echo "==== install ${MODULE} ${ARCH} done."
		fi
		;;
	"uninstall")
		MAKE="make ARCH=${ARCH}"
		${MAKE} uninstall > /dev/null
		if [ $? -ne 0 ]; then
			echo "==== uninstall ${MODULE} failed"
			return;
		else
			echo "==== uninstall ${MODULE} ${ARCH} done."
		fi
		;;
	*)
		MAKE="make ARCH=${ARCH} OUTPUT=${OUTPUT}"
		if [[ ${ARCH} == "x86" || ${ARCH} == "pi" ]]; then
			${MAKE} > /dev/null
		else
			make -f Makefile.${ARCH} > /dev/null
		fi
		${MAKE} install > /dev/null
		if [ $? -ne 0 ]; then
			echo "==== build ${MODULE} failed"
			return;
		else
			echo "==== build ${MODULE} ${ARCH} done."
		fi
		;;
	esac
}

build_all()
{
	for item in $BASIC_LIBS $NETWORK_LIBS; do
		MODULE="$item"
		ARG2=$1
		build_module $MODULE $ARG2
	done
}

do_build()
{
	case $MODULE in
		"all")
		build_all;;
	"clean")
		build_all clean;;
	"install")
		build_all install;;
	"uninstall")
		build_all uninstall;;
	"help")
		usage;;
	*)
		build_module $MODULE;;
	esac
}

config_arch
config_common
check_output
do_build
