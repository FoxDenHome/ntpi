#!/bin/bash
set -ex

echo "#######################################"
echo "EXTRACING TIMEBEAT"
echo "#######################################"
mkdir -p /tmp/timebeat-deb /tmp/timebeat-data
ar vx /input/download/timebeat.deb --output=/tmp/timebeat-deb
tar -C/tmp/timebeat-data -xf /tmp/timebeat-deb/data.*

rm -rf /input/rootfs/usr/share/timebeat
cp -r /tmp/timebeat-data/usr/share/timebeat /input/rootfs/usr/share/timebeat

echo "#######################################"
echo "COMPILING LINUXPTP"
echo "#######################################"
mkdir -p /tmp/linuxptp-src
tar -C/tmp/linuxptp-src --strip-components=1 -xf /input/download/linuxptp.tgz
cd "/tmp/linuxptp-src"

patch -p1 -i /input/src/linuxptp-ts2phc-add-baudrate-option.patch

make "-j$(nproc)"
make install
cp /usr/local/sbin/* /input/rootfs/usr/sbin/

echo "#######################################"
echo "COMPILING UTILITIES"
echo "#######################################"
gcc /input/src/testptp.c -O2 -o /input/rootfs/usr/sbin/testptp
