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





echo "#######################################"
echo "COMPILING LINUXPTP"
echo "#######################################"
mkdir -p /tmp/ptp
tar -C/tmp/ptp -xf /input/src/linuxptp-3.1.1.tgz
cd /tmp/ptp/linuxptp-3.1.1

sed 's~#define BAUD\s.*~#define BAUD 115200~g' -i ts2phc_nmea_master.c

make "-j$(nproc)"
make install
cp /usr/local/sbin/* /input/rootfs/sbin/

echo "#######################################"
echo "COMPILING SET-TAI.C"
echo "#######################################"
gcc /input/src/set-tai.c -O2 -o /input/rootfs/sbin/set-tai
