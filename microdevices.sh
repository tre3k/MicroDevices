#!/usr/bin/env bash

# microdevices.sh: manage of firmware for some devices
# Copyright (C) 2025 Kirill Pshenichnyi <pshcyrill@mail.ru>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.


# Set this variables if you need special versions for U-Boot and Linux kernel
UBOOT_VERSION=v2024.01
LINUX_VERSION=v6.7

# Set default (if you need) prefex for coross-compiler, also architecture
if [[ -z $CROSS_COMPILE ]]; then
    export CROSS_COMPILE=arm-linux-gnueabihf-
fi
if [[ -z $ARCH ]]; then export ARCH=arm; fi

# Add options for make
if [[ -z $MAKE_OPTIONS ]]; then
    MAKE_OPTIONS="-j8"
fi

# Not edit this variable
ROOTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# You can edit if you want get Linux or U-boot from not official repos.
LINUX_REPO="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
UBOOT_REPO="https://source.denx.de/u-boot/u-boot.git"

ROOTFS_URL="http://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz"
ROOTFS_RPI_URL="http://ca.us.mirror.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz"

LINUX_DIR=${ROOTDIR}/linux
UBOOT_DIR=${ROOTDIR}/u-boot

repo_dirs=(${LINUX_DIR} ${UBOOT_DIR})
repo_urls=(${LINUX_REPO} ${UBOOT_REPO})


function help() {
    echo $0 "<oprions/device> <command>"
    echo -e "\033[1m    options: \033[0m"
    echo -e "\t--get-repos\r\t\t\tGet linux and u-boot from git repositories"
    echo -e "\t--sync-repos\r\t\t\tSync remote git repos with local"
    echo -e "\t--help, -h\r\t\t\tThis message"
    echo ""
    echo -e "\033[1m    devices: \033[0m"
    echo -e "\tde10-nano\r\t\t\tBoard on Altera Cyclon V FPGA SoC"
    echo -e "\trpi3b\r\t\t\tRaspberryPI 3B v1.2"
    echo ""
    echo -e "\033[1m    commands: \033[0m"
    echo -e "\tbuild\r\t\t\t\t\tBuild u-boot and linux kernel"
    echo -e "\tremote-install-arch <SD dev>\r\t\t\t\t\tAutomatic install image from archlinuxarm.org"
    exit
}

function getRepos() {
    count=0
    for repo in ${repo_urls[@]}; do
        git clone ${repo} ${repo_dirs[count]}
        count=$(($count+1))
    done
}

function syncRepos(){
    for dir in ${repo_dirs[@]}; do
        cd ${dir}
        git switch master
        git fetch
        git rebase
    done
    cd ${ROOTDIR}
}

## ARGS: devName, command
function _deviceCommand() {
    case $2 in
        "build")
            ${1}Build
            ;;

	"remote-install-arch")
	    mkdir -p ${ROOTDIR}/workdir
	    mkdir -p ${ROOTDIR}/workdir/${1}
	    workdir=${ROOTDIR}/workdir/${1}

	    ${1}RemoteInstallArch $3
	    ;;

        *)
            echo "see 'command' section in help"
            exit
            ;;
    esac
}

# Arg: name in "configs" directory
function _buildUBoot () {
    cd ${UBOOT_DIR}
    if [[ -z $UBOOT_VERSION ]]; then
        git checkout master
    else
        git checkout ${UBOOT_VERSION}
    fi

    make clean
    cp ${ROOTDIR}/configs/$1/u-boot.config ./.config
    make oldconfig
    make ${MAKE_OPTIONS}
}

# Arg: name in "configs" directory
function _buildLinux () {
    cd ${LINUX_DIR}
    if [[ -z $LINUX_VERSION ]]; then
        git checkout master
    else
        git checkout ${LINUX_VERSION}
    fi

    make clean
    cp ${ROOTDIR}/configs/$1/linux.config ./.config
    make oldconfig
    make ${MAKE_OPTIONS}
}


function de10NanoBuild() {
    NAME="de10-nano"
    echo -e "\033[1m Stage 1: build Das U-Boot\033[0m"
    _buildUBoot ${NAME}

    echo -e "\033[1m Stage 2: build Linux kernel\033[0m"
    _buildLinux ${NAME}
}

function rpi3BBuild() {
    echo "RaspberryPI 3B build"
}

function rpi3BRemoteInstallArch() {
    cd ${workdir}
    root_archive=ArchLinuxARM-rpi-armv7-latest.tar.gz
    root_URL=http://fl.us.mirror.archlinuxarm.org/os/

    echo "Remote arch install"

    echo "o
          p
          n
          p
          1

          +200M
          t
          c
          n
          p



          w" | fdisk ${1}
    mkfs.vfat ${1}1
    mkfs.ext4 ${1}2

    mkdir -p ${workdir}/boot
    mkdir -p ${workdir}/root

    mount ${1}1 ${workdir}/boot
    mount ${1}2 ${workdir}/root

    if [[ -f ${root_archive} ]]; then
	md5sum_current=(`md5sum ${root_archive}`)
	md5sum_remote=(`curl ${root_URL}${root_archive}.md5`)
	echo ${md5sum_remote[0]} ${md5sum_current[0]}
    else
	md5sum_current=("NOT DOWNLAODED")
    fi

    if [[ ${md5sum_remote[0]} != ${md5sum_current[0]} ]]; then
	wget ${root_URL}${root_archive}
    fi

    echo "Unpacking..."
    bsdtar -xpf ArchLinuxARM-rpi-armv7-latest.tar.gz -C root
    sync

    mv root/boot/* boot
    umount boot root

    echo -e "\033[1m"
    echo "Insert the SD card into the Raspberry Pi, connect ethernet, and apply 5V power."
    echo "Use the serial console or SSH to the IP address given to the board by your router."
    echo -e "\t - Login as the default user alarm with the password alarm."
    echo -e "\t - The default root password is root."
    echo "Initialize the pacman keyring and populate the Arch Linux ARM package signing keys"
    echo -e "\tpacman-key --init"
    echo -e "\tpacman-key --populate archlinuxarm"
    echo -e "\033[0m"
}

case $1 in
    "--get-repos")
        getRepos
        ;;

    "--sync-repos")
        syncRepos
        ;;

    "de10-nano")
        _deviceCommand de10Nano $2 $3
        ;;

    "rpi3b")
        _deviceCommand rpi3B $2 $3
        ;;

    "--help")
        help
        ;;

    "-h")
        help
        ;;

    *)
        help
        ;;
esac
