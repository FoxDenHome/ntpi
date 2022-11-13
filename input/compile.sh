#!/bin/sh
set -ex

export EXTRA_CFLAGS="-O2 -flto"
export EXTRA_LDFLAGS="-flto"

#echo "#######################################"
#echo "EXTRACING TIMEBEAT"
#echo "#######################################"
#mkdir -p /tmp/timebeat-deb /tmp/timebeat-data
#ar vx "$CACHE_PATH/download/timebeat.deb" --output=/tmp/timebeat-deb
#tar -C/tmp/timebeat-data -xf /tmp/timebeat-deb/data.*

#cp -r /tmp/timebeat-data/usr/share/timebeat "$ROOTFS_PATH/usr/share/timebeat"

echo "#######################################"
echo "COMPILING LINUXPTP"
echo "#######################################"
mkdir -p /tmp/linuxptp-src
tar -C/tmp/linuxptp-src --strip-components=1 -xf "$CACHE_PATH/download/linuxptp.tgz"
cd "/tmp/linuxptp-src"

patch -p1 -i "$INPUT_PATH/src/linuxptp-ts2phc-add-baudrate-option.patch"

make "-j$(nproc)"
make install
cp /usr/local/sbin/* "$ROOTFS_PATH/usr/sbin/"

echo "#######################################"
echo "COMPILING UTILITIES"
echo "#######################################"
gcc "$INPUT_PATH/src/testptp.c" $EXTRA_CFLAGS -o "$ROOTFS_PATH/usr/sbin/testptp"
