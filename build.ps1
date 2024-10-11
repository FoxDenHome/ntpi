. .\shared.ps1

$env:DEFAULT_KERNEL_MODULES='*'
$env:CMDLINE='console=tty1 root=/dev/root rootfstype=ext4 fsck.repair=yes ro rootwait'

Exec { git rev-parse HEAD > input/rootfs/etc/image_commit }
Exec { Get-date > input/rootfs/etc/image_date }
Exec { git ls-files .\input\rootfs\ --stage --full-name > input/rootfs-ls-files }

Exec { docker pull --platform=linux/arm64 ghcr.io/raspi-alpine/builder }
Exec { docker buildx build --platform=linux/arm64 -t customized_alpine_builder builderimage }
Exec { docker run --platform=linux/arm64 --rm -it -e CACHE_PATH=/cache -e DEFAULT_HOSTNAME=ntpi -e ARCH=aarch64 -e DEFAULT_TIMEZONE=America/Los_Angeles -e CMDLINE -e DEFAULT_KERNEL_MODULES -e SIZE_ROOT_PART=1000M -e SIZE_ROOT_FS=0 -v "$PWD/cache:/cache" -v "$PWD/input:/input" -v "$PWD/output:/output" customized_alpine_builder }
