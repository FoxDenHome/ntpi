#!/bin/sh
set -e

cd "$(dirname "$0")"

rm -rf output && mkdir -p output
rm -rf input/tmp && mkdir -p input/tmp

export DEFAULT_KERNEL_MODULES="8021q af_packet bridge dwc2 garp i2c-mux i2c-mux-pinctrl ipv6 llc pps-gpio pps-ldisc raspberrypi-hwmon roles rtc-pcf85063 stp"
export CMDLINE="console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait"

git rev-parse HEAD > input/rootfs/etc/image_commit
date > input/rootfs/etc/image_date

#docker buildx build --platform=linux/arm64 -t ntp-alpine-compiler compiler
#docker run --platform=linux/arm64 --rm -it --entrypoint=/input/compile.sh -v "$PWD/input:/input" ntp-alpine-compiler

IMG="ghcr.io/raspi-alpine/builder"
docker pull "$IMG"
docker run --rm -it -e DEFAULT_HOSTNAME=ntp -e ARCH=aarch64 -e DEFAULT_TIMEZONE=America/Los_Angeles -e CMDLINE -e DEFAULT_KERNEL_MODULES -e SIZE_ROOT_PART=1000M -e SIZE_ROOT_FS=0 -v "$PWD/input:/input" -v "$PWD/output:/output" "$IMG"
