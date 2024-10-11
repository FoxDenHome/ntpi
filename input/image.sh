#!/bin/bash
set -ex

# Configure boot process
mkenvimage -s 0x4000 -o "$BOOTFS_PATH/uboot.env" "$INPUT_PATH/uboot.env"
cat "$INPUT_PATH/usercfg.txt" > "$BOOTFS_PATH/usercfg.txt"
echo 'include usercfg.txt' >> "$BOOTFS_PATH/config.txt"

# Install packages
echo "@testing=http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> "$ROOTFS_PATH/etc/apk/repositories"
chroot_exec apk update
chroot_exec apk upgrade
chroot_exec apk add s6 s6-openrc pps-tools git i2c-tools bridge-utils chrony htop curl screen prometheus-node-exporter gpsd gpsd-clients bridge wget sudo tcpdump nano openssh-sftp-server ethtool keepalived keepalived-openrc python3 py3-cffi py3-smbus py3-pyserial py3-gpsd py3-requests raspberrypi libc6-compat net-snmp oh-my-zsh zsh
chroot_exec apk add kanidm-openrc@testing kanidm-clients@testing kanidm-unixd-clients@testing kanidm-zsh-completion@testing

# Run compilation and inclusion steps for external code
"$INPUT_PATH/download.sh"
"$INPUT_PATH/compile.sh"

# Configure services
chroot_exec rc-update del rngd sysinit
chroot_exec rc-update del ntpd default
chroot_exec rc-update del ab_clock default
chroot_exec rc-update add s6 default
chroot_exec rc-update add hwclock

# Configure kernel modules
echo -n > "$ROOTFS_PATH/etc/modules"
for mod in ${DEFAULT_KERNEL_MODULES}
do
    echo "$mod" >> "$ROOTFS_PATH/etc/modules"
done
echo 'Loading the following modules:'
cat "$ROOTFS_PATH/etc/modules"
echo 'END OF MODULE LIST'

# Add additional tmpfs entries
echo >> "$ROOTFS_PATH/etc/fstab"
add_tmpfs() {
    TMP_PATH="$1"
    mkdir -p "$ROOTFS_PATH/$TMP_PATH"
    echo "tmpfs $TMP_PATH tmpfs defaults 0 0" >> "$ROOTFS_PATH/etc/fstab"
}
add_tmpfs '/var/log'

# Undo things the image creator did we don't want
revert_data_ln() {
    LN_PATH="$1"
    rm -f "$ROOTFS_PATH/$LN_PATH" || rmdir "$ROOTFS_PATH/$LN_PATH"
    mv "$DATAFS_PATH/$LN_PATH" "$ROOTFS_PATH/$LN_PATH"
}
revert_data_override() {
    LN_PATH="$1"
    rm -f "$ROOTFS_PATH/$LN_PATH" || rmdir "$ROOTFS_PATH/$LN_PATH"
    mv "$ROOTFS_PATH/${LN_PATH}_org" "$ROOTFS_PATH/$LN_PATH"
}
revert_data_ln '/etc/hostname'
revert_data_ln '/etc/network/interfaces'
sed 's~/data/etc/~/tmp/~g' -i "$ROOTFS_PATH/etc/udhcpc/udhcpc.conf"
revert_data_ln '/etc/localtime'
revert_data_ln '/etc/timezone'
revert_data_override '/etc/conf.d/dropbear'

rm -rf "$ROOTFS_PATH/home" "$ROOTFS_PATH/root"
mkdir -p "$ROOTFS_PATH/home" "$ROOTFS_PATH/root"
chown 0:0 "$ROOTFS_PATH/home" "$ROOTFS_PATH/root"
chmod 700 "$ROOTFS_PATH/root"

# Copy our rootfs additions
cp -d -r "$INPUT_PATH/rootfs/"* "$ROOTFS_PATH"

while read lineraw; do
    line="$(echo -n "$lineraw" | sed 's/\s\s*/ /g')"
    TMODE="$(echo -n "$line" | cut -d' ' -f1 | sed 's/^100//')"
    TPATH="$(echo -n "$line" | cut -d' ' -f4 | cut -d'/' '-f3-')"
    chmod "$TMODE" "$ROOTFS_PATH/$TPATH"
done < "$INPUT_PATH/rootfs-ls-files"

ln -s '/data/etc/adjtime' "$ROOTFS_PATH/etc/adjtime"

IMAGE_COMMIT="$(cat "$ROOTFS_PATH/etc/image_commit" | tr -d "\r\n\t")"
IMAGE_DATE="$(cat "$ROOTFS_PATH/etc/image_date" | tr -d "\r\n\t")"
sed "s/__IMAGE_COMMIT__/$IMAGE_COMMIT/" -i "$ROOTFS_PATH/etc/motd"
sed "s/__IMAGE_DATE__/$IMAGE_DATE/" -i "$ROOTFS_PATH/etc/motd"

# Add users
chroot_exec addgroup breakglass

add_user() {
    ADDUSER="$1"
    ADDUSER="$1"

    chroot_exec adduser -D "$ADDUSER"
    chroot_exec adduser "$ADDUSER" breakglass

    chroot_exec rm -rf "/home/$ADDUSER"

    chroot_exec usermod -s /bin/zsh "$ADDUSER"
    chroot_exec cp -rv /etc/skel/. "/home/$ADDUSER"

    chroot_exec mkdir -p "/home/$ADDUSER/.ssh"
    cp -vf "$INPUT_PATH/keys/$ADDUSER" "$ROOTFS_PATH/home/$ADDUSER/.ssh/authorized_keys"
    chroot_exec chown -R "$ADDUSER:$ADDUSER" "/home/$ADDUSER"
    chroot_exec chmod 700 "/home/$ADDUSER" "/home/$ADDUSER/.ssh"
    chroot_exec chmod 600 "/home/$ADDUSER/.ssh/authorized_keys"
}

add_user doridian-bg
add_user wizzy-bg
