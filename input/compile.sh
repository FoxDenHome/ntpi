#!/bin/bash
set -e

cd /tmp
git clone https://github.com/wowczarek/ptpd.git
cd ptpd

autoreconf -vi

./configure


DEF_FILE='src/constants.h'
echo '' >> "$DEF_FILE"
echo 'typedef unsigned char u_char;' >> "$DEF_FILE"
echo 'typedef unsigned int u_int;' >> "$DEF_FILE"
echo 'typedef unsigned short u_short;' >> "$DEF_FILE"

CONFIG_H='src/config.h'
echo '' >> "$CONFIG_H"
echo '#undef HAVE_NETINET_IF_ETHER_H' >> "$CONFIG_H"

#cat config.h
#exit 1

make "-j$(nproc)"
