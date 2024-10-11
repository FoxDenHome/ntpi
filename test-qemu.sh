#!/bin/sh
set -e

#./build.sh

rm -f testimg/sdcard.img
cp output/sdcard.img testimg/sdcard.img
qemu-img resize testimg/sdcard.img 4G
sudo docker run --rm -it --entrypoint=/bin/sh -v "$PWD/testimg:/testimg" customized_alpine_builder -c "cp /uboot/u-boot_rpi-64.bin /testimg/u-boot_rpi-64.bin"

qemu-system-aarch64 -M raspi3b \
    -append 'console=ttyAMA0,115200 earlyprintk console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait' \
    -dtb testimg/bcm2710-rpi-3-b.dtb \
    -kernel testimg/u-boot_rpi-64.bin \
    -sd testimg/sdcard.img \
    -m 1G \
    -smp 4 \
    -serial stdio \
    -device usb-net,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::5555-:22
