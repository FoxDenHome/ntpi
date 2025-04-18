#!/bin/sh
set -e

git config --global user.email 'ntpi-builder@foxden.network'
git config --global user.name 'ntpi-builder'

mkdir -p "$CACHE_PATH/download" && rm -f "$CACHE_PATH/download/"*.tmp

hash_check() {
    local FILE="$1"
    local EXPECTED_HASH="$2"

    if [ ! -f "$FILE" ]
    then
        echo 1
    else
        MEASURED_HASH="$(sha256sum -b "$FILE" | cut -d' ' -f1)"
        if [ "$MEASURED_HASH" != "$EXPECTED_HASH" ]
        then
            echo "Got: $MEASURED_HASH != Wanted: $EXPECTED_HASH" > /dev/stderr
            echo 2
        else
            echo 0
        fi
    fi
}

download_if_needed() {
    local URL="$1"
    local HASH="$2"
    local DEST="$CACHE_PATH/download/$3"

    if [ `hash_check "$DEST" "$HASH"` != "0" ]
    then
        echo "Downloading $URL to $DEST"
        rm -f "$DEST.tmp"

        wget -O "$DEST.tmp" "$URL"
        if [ `hash_check "$DEST.tmp" "$HASH"` != "0" ]
        then
            sha256sum -b "$DEST.tmp"
            echo "$HASH"
            echo 'Hash mismatch on download!'
            exit 1
        fi

        rm -f "$DEST"
        mv "$DEST.tmp" "$DEST"
    else
        echo "Skipping download of $URL to $DEST"
    fi
}

download_if_needed 'https://github.com/FoxDenHome/linuxptp/archive/refs/tags/v3.1.1-dori2.tar.gz' 'dacb4ce8609963101232159ca99a49d1301208b1902ddb7ea658852d82ce658f' 'linuxptp.tgz'
#download_if_needed 'https://timebeat.app/assets/packages/timebeat-1.4.4-arm64.deb' 'b1c8366847bcec6ae56a728dc60dda1675b6abab7ecc2ced51e1bba8f90f3b3a' 'timebeat.deb'

if [ ! -d "$CACHE_PATH/download/aports" ]
then
    git clone https://gitlab.alpinelinux.org/alpine/aports.git "$CACHE_PATH/download/aports"
fi

APORTS_BRANCH="3.21-stable"
cd "$CACHE_PATH/download/aports"
git checkout "${APORTS_BRANCH}"
git pull
git reset --hard "origin/${APORTS_BRANCH}"
git cherry-pick bb0613ae45c57b71a7bd748428ccf9c7ca6521dc
git cherry-pick c8a02efd5d56bc22957a0fca5d28f76ad0651a9a
git clean -fdx
