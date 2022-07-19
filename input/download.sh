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

download_if_needed 'https://downloads.sourceforge.net/project/linuxptp/v3.1/linuxptp-3.1.1.tgz' '94d6855f9b7f2d8e9b0ca6d384e3fae6226ce6fc012dbad02608bdef3be1c0d9' 'linuxptp.tgz'
#download_if_needed 'https://timebeat.app/assets/packages/timebeat-1.4.4-arm64.deb' 'b1c8366847bcec6ae56a728dc60dda1675b6abab7ecc2ced51e1bba8f90f3b3a' 'timebeat.deb'
