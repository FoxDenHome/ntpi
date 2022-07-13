#!/bin/bash
set -e

cd /tmp
git clone https://github.com/wowczarek/ptpd.git
cd ptpd

DEF_FILE='src/constants.h'
echo '' >> "$DEF_FILE"
echo 'typedef unsigned char u_char;' >> "$DEF_FILE"
echo 'typedef unsigned int u_int;' >> "$DEF_FILE"
echo 'typedef unsigned short u_short;' >> "$DEF_FILE"

find src/libcck -type f | xargs -n1 sed 's~#include <linux/ethtool.h>~#include <netinet/if_ether.h>\n#include <linux/ethtool.h>~' -i
find src/libcck -type f | xargs -n1 sed 's~#include <linux/if_ether.h>~#include <netinet/if_ether.h>\n#include <linux/if_ether.h>~' -i

autoreconf -vi
./configure
make "-j$(nproc)"

cp src/ptpd /input/rootfs/sbin/ptpd
