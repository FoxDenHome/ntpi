#!/bin/sh
set -ex

export EXTRA_CFLAGS="-O2 -flto"
export EXTRA_LDFLAGS="-flto"

echo "#######################################"
echo "COMPILING LINUXPTP"
echo "#######################################"
mkdir -p /tmp/linuxptp-src
tar -C/tmp/linuxptp-src --strip-components=1 -xf "$CACHE_PATH/download/linuxptp.tgz"
cd "/tmp/linuxptp-src"

patch -p1 -i "$INPUT_PATH/src/linuxptp-minor-version-2-0.patch"

make "-j$(nproc)"
make install
cp /usr/local/sbin/* "$ROOTFS_PATH/usr/sbin/"

echo "#######################################"
echo "COMPILING UTILITIES"
echo "#######################################"
gcc "$INPUT_PATH/src/testptp.c" $EXTRA_CFLAGS -o "$ROOTFS_PATH/usr/sbin/testptp"
