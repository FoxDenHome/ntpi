#!/bin/sh
set -e

SHELL=/bin/zsh

mksysuser() {
    groupadd -g "$2" "$1"
    adduser --shell /sbin/nologin --gid "$2" --uid "$2" "$1"
}

mknasuser() {
    groupadd -g "$2" "$1"
    useradd --shell "$SHELL" --gid "$2" --uid "$2" "$1"
    adduser "$1" share
}

mksysuser smbauth  401
mksysuser smbguest 403
mksysuser share    1000
mknasuser doridian 1001
mknasuser wizzy    1002
