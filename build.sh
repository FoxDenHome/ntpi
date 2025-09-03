#!/bin/sh
set -ex

cd "$(dirname "$0")"

rm -rf output && mkdir -p output

export DEFAULT_KERNEL_MODULES='*'
export CMDLINE='console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait'
export ALPINE_BRANCH=3.22

git rev-parse HEAD > input/rootfs/etc/image_commit
date > input/rootfs/etc/image_date

export BUILD_IMAGE='registry.gitlab.com/raspi-alpine/builder/master:latest'

docker pull --platform=linux/arm64 "${BUILD_IMAGE}"
docker run --platform=linux/arm64 --rm -it -e CACHE_PATH=/cache -e DEFAULT_HOSTNAME=ntpi -e ARCH=aarch64 -e DEFAULT_TIMEZONE=America/Los_Angeles -e ALPINE_BRANCH -e CMDLINE -e DEFAULT_KERNEL_MODULES -e SIZE_ROOT_PART=1000M -e SIZE_ROOT_FS=0 -v "$PWD/cache:/cache" -v "$PWD/input:/input" -v "$PWD/output:/output" "${BUILD_IMAGE}"
