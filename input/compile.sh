#!/bin/sh
set -ex

export EXTRA_CFLAGS="-O2 -flto"
export EXTRA_LDFLAGS="-flto"

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
chroot_exec /bin/sh -c 'rm -fv /tmp/*openrc*.apk /tmp/*doc*.apk'
chroot_exec /bin/sh -c 'apk add --allow-untrusted /tmp/*.apk'
chroot_exec /bin/sh -c 'rm -fv /tmp/*.apk'

echo "#######################################"
echo "COMPILING LINUXPTP"
echo "#######################################"
mkdir -p /tmp/linuxptp-src
tar -C/tmp/linuxptp-src --strip-components=1 -xf "$CACHE_PATH/download/linuxptp.tgz"
cd "/tmp/linuxptp-src"

make "-j$(nproc)"
make install
cp /usr/local/sbin/* "$ROOTFS_PATH/usr/sbin/"

echo "#######################################"
echo "COMPILING UTILITIES"
echo "#######################################"
gcc "$INPUT_PATH/src/testptp.c" $EXTRA_CFLAGS -o "$ROOTFS_PATH/usr/sbin/testptp"
