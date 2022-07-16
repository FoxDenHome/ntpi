#!/bin/bash
set -ex

LINUXPTP_VERSION=3.1
LINUXPTP_VERSION_FULL=3.1.1
echo "#######################################"
echo "COMPILING LINUXPTP"
echo "#######################################"
mkdir -p /tmp/linuxptp-src
wget "http://downloads.sourceforge.net/project/linuxptp/v$LINUXPTP_VERSION/linuxptp-$LINUXPTP_VERSION_FULL.tgz" -O /tmp/linuxptp.tgz
tar -C/tmp/linuxptp-src --strip-components=1 -xf /tmp/linuxptp.tgz
cd "/tmp/linuxptp-src"

patch -p1 -i /input/src/linuxptp-ts2phc-add-baudrate-option.patch

make "-j$(nproc)"
make install
cp /usr/local/sbin/* /input/rootfs/usr/sbin/

echo "#######################################"
echo "COMPILING UTILITIES"
echo "#######################################"
gcc /input/src/testptp.c -O2 -o /input/rootfs/usr/sbin/testptp
