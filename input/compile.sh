#!/bin/bash
set -ex




#echo "#######################################"
#echo "COMPILING PTPD"
#echo "#######################################"
#
#cd /tmp
#git clone https://github.com/wowczarek/ptpd.git
#cd /tmp/ptpd
#
#DEF_FILE='src/constants.h'
#echo '' >> "$DEF_FILE"
#echo 'typedef unsigned char u_char;' >> "$DEF_FILE"
#echo 'typedef unsigned int u_int;' >> "$DEF_FILE"
#echo 'typedef unsigned short u_short;' >> "$DEF_FILE"
#
#find src/libcck -type f | xargs -n1 sed 's~#include <linux/ethtool.h>~#include <netinet/if_ether.h>\n#include <linux/ethtool.h>~' -i
#find src/libcck -type f | xargs -n1 sed 's~#include <linux/if_ether.h>~#include <netinet/if_ether.h>\n#include <linux/if_ether.h>~' -i
#
#autoreconf -vi
#./configure
#make "-j$(nproc)"
#cp src/ptpd /input/rootfs/sbin/




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
cp /usr/local/sbin/* /input/rootfs/sbin/

echo "#######################################"
echo "COMPILING UTILITIES"
echo "#######################################"
gcc /input/src/testptp.c -O2 -o /input/rootfs/sbin/testptp
