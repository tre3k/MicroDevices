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


ROOTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

LINUX_DIR=${ROOTDIR}/linux
UBOOT_DIR=${ROOTDIR}/u-boot

LINUX_REPO="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
UBOOT_REPO="https://source.denx.de/u-boot/u-boot.git"

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
    echo -e "\tbuild\r\t\t\tBuild u-boot and linux kernel"
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
        git fetch
        git rebase
    done
    cd ${ROOTDIR}
}

## devName, command
function _deviceCommand() {
    case $2 in
        "build")
            ${1}Build
            ;;
        *)
            echo "see 'command' section in help"
            exit
            ;;
    esac
}


function de10NanoBuild() {
    echo "de10-nano build"
}

function rpi3BBuild() {
    echo "RaspberryPI 3B build"
}

case $1 in
    "--get-repos")
        getRepos
        ;;

    "--sync-repos")
        syncRepos
        ;;

    "de10-nano")
        _deviceCommand de10Nano $2
        ;;

    "rpi3b")
        _deviceCommand rpi3B $2
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
