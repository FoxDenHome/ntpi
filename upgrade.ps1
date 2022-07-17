. .\shared.ps1

$DEST=$args[0]

Exec {
    echo "put output/sdcard_update.img.gz /tmp/sdcard_update.img.gz
put output/sdcard_update.img.gz.sha256 /tmp/sdcard_update.img.gz.sha256" | sftp -b - "$DEST"
}

Exec {
    ssh -t "$DEST" "sudo -n /bin/sh -l -c 'ab_flash /tmp/sdcard_update.img.gz && reboot'"
}
