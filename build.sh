#!/bin/sh
set -e

cd "$(dirname "$0")"

rm -rf output && mkdir -p output
rm -rf input/tmp && mkdir -p input/tmp
mkdir -p input/download && rm -f input/download/*.tmp

hash_check() {
    local FILE="$1"
    local EXPECTED_HASH="$2"

    if [ ! -f "$FILE" ]
    then
        echo 1
    else
        MEASURED_HASH="$(sha256sum -b "$FILE" | cut -d' ' -f1)"
        if [ "$MEASURED_HASH" != "$EXPECTED_HASH" ]
        then
            echo "Got: $MEASURED_HASH != Wanted: $EXPECTED_HASH" > /dev/stderr
            echo 2
        else
            echo 0
        fi
    fi
}

download_if_needed() {
    local URL="$1"
    local HASH="$2"
    local DEST="./input/download/$3"

    if [ `hash_check "$DEST" "$HASH"` != "0" ]
    then
        echo "Downloading $URL to $DEST"
        rm -f "$DEST.tmp"

        wget -O "$DEST.tmp" "$URL"
        if [ `hash_check "$DEST.tmp" "$HASH"` != "0" ]
        then
            sha256sum -b "$DEST.tmp"
            echo "$HASH"
            echo 'Hash mismatch on download!'
            exit 1
        fi

        rm -f "$DEST"
        mv "$DEST.tmp" "$DEST"
    else
        echo "Skipping download of $URL to $DEST"
    fi
}

export DEFAULT_KERNEL_MODULES='8021q af_packet bridge dwc2 garp i2c-mux i2c-mux-pinctrl ipv6 llc pps-gpio pps-ldisc raspberrypi-hwmon roles rtc-pcf85063 stp'
export CMDLINE='console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait'

git rev-parse HEAD > input/rootfs/etc/image_commit
date > input/rootfs/etc/image_date

download_if_needed 'https://downloads.sourceforge.net/project/linuxptp/v3.1/linuxptp-3.1.1.tgz' '94d6855f9b7f2d8e9b0ca6d384e3fae6226ce6fc012dbad02608bdef3be1c0d9' 'linuxptp.tgz'
download_if_needed 'https://timebeat.app/assets/packages/timebeat-1.4.4-arm64.deb' 'b1c8366847bcec6ae56a728dc60dda1675b6abab7ecc2ced51e1bba8f90f3b3a' 'timebeat.deb'

#docker buildx build --platform=linux/arm64 -t ntp-alpine-compiler compiler
docker run --platform=linux/arm64 --rm -it --entrypoint=/input/compile.sh -v "$PWD/input:/input" ntp-alpine-compiler

IMG='ghcr.io/raspi-alpine/builder'
docker pull "$IMG"
docker run --rm -it -e DEFAULT_HOSTNAME=ntp -e ARCH=aarch64 -e DEFAULT_TIMEZONE=America/Los_Angeles -e CMDLINE -e DEFAULT_KERNEL_MODULES -e SIZE_ROOT_PART=1000M -e SIZE_ROOT_FS=0 -v "$PWD/input:/input" -v "$PWD/output:/output" "$IMG"
