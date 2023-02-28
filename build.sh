#!/bin/sh
set -ex

cd "$(dirname "$0")"

rm -rf output && mkdir -p output

export DEFAULT_KERNEL_MODULES='8021q af_packet bridge dwc2 garp i2c-dev i2c-mux i2c-mux-pinctrl ipv6 llc pps-gpio pps-ldisc raspberrypi-hwmon roles rtc-pcf85063 stp ftdi_sio'
export CMDLINE='console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait'

git rev-parse HEAD > input/rootfs/etc/image_commit
date > input/rootfs/etc/image_date
git ls-files input/rootfs/ --stage --full-name > input/rootfs-ls-files

docker pull --platform=linux/arm64 ghcr.io/raspi-alpine/builder:latest
docker buildx build --platform=linux/arm64 -t customized_alpine_builder builderimage --load
docker run --platform=linux/arm64 --rm -it -e CACHE_PATH=/cache -e DEFAULT_HOSTNAME=ntp -e ARCH=aarch64 -e DEFAULT_TIMEZONE=America/Los_Angeles -e CMDLINE -e DEFAULT_KERNEL_MODULES -e SIZE_ROOT_PART=1000M -e SIZE_ROOT_FS=0 -v "$PWD/cache:/cache" -v "$PWD/input:/input" -v "$PWD/output:/output" customized_alpine_builder
