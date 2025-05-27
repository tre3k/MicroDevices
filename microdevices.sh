#!/usr/bin/env bash

ROOTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

LINUX_DIR=${ROOTDIR}/linux
UBOOT_DIR=${ROOTDIR}/u-boot

LINUX_REPO="git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
UBOOT_REPO="https://source.denx.de/u-boot/u-boot.git"

repo_dirs=(${LINUX_DIR} ${UBOOT_DIR})
repo_urls=(${LINUX_REPO} ${UBOOT_REPO})

function help() {
    echo $0 "<oprions/device> <command>"
    echo "options: "
    echo -e "\t--get-repos\r\t\t\tGet linux and u-boot from git repositories"
    echo -e "\t--sync-repos\r\t\t\tSync remote git repos with local"
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

case $1 in
    "--get-repos")
        getRepos
        ;;

    "--sync-repos")
        syncRepos
        ;;

    *)
        help
        ;;
esac
