#!/bin/sh
set -e

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

download_if_needed 'https://github.com/nwtime/linuxptp/archive/refs/tags/v4.4.tar.gz' '61757bc0a58d789b8fcbdddf56c88a0230597184a70dcb2ac05b4c6b619f7d5c' 'linuxptp.tgz'
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
git clean -fdx
patch -p1 -i "$INPUT_PATH/aports.patch"
