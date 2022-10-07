#!/bin/sh

colour_echo ">> Compress update image"
# copy final image
mkdir -p ${OUTPUT_PATH}
mv ${IMAGE_PATH}/sdcard.img ${OUTPUT_PATH}/${IMG_NAME}.img
pigz -c ${IMAGE_PATH}/rootfs.ext4 >${OUTPUT_PATH}/${IMG_NAME}_update.img.gz

# create checksums
cd ${OUTPUT_PATH}/
sha256sum ${IMG_NAME}_update.img.gz >${IMG_NAME}_update.img.gz.sha256
