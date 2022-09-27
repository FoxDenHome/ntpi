#!/bin/sh

echo 'Fixing resolv.conf to be baked in...'

rm -f "${ROOTFS_PATH}/etc/resolv.conf"
echo 'nameserver 10.1.0.53' > "${ROOTFS_PATH}/etc/resolv.conf"
