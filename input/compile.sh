#!/bin/sh
set -ex

echo "#######################################"
echo "COMPILING CHRONY + GPSD"
echo "#######################################"

doabuild() {
    abuild -r -F validate builddeps clean fetch unpack prepare mkusers build rootpkg
}

cd "$CACHE_PATH/download/aports/main/chrony"
doabuild
cd "$CACHE_PATH/download/aports/main/gpsd"
doabuild
cd /tmp

cp -v ~/packages/main/aarch64/*.apk "$ROOTFS_PATH/tmp/"
chroot_exec /bin/sh -c 'rm -fv /tmp/*openrc*.apk /tmp/*doc*.apk /tmp/*dev*.apk /tmp/*dbg*.apk'
chroot_exec /bin/sh -c 'apk add --allow-untrusted /tmp/*.apk'
chroot_exec /bin/sh -c 'rm -fv /tmp/*.apk'