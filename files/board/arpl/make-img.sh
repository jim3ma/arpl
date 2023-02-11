#!/usr/bin/env bash
# CONFIG_DIR = .
# $1 = Target path = ./output/target
# BR2_DL_DIR = ./dl
# BINARIES_DIR = ./output/images
# BUILD_DIR = ./output/build
# BASE_DIR = ./output

set -ex

# Define some constants
MY_ROOT="${CONFIG_DIR}/.."
IMAGE_FILE="${MY_ROOT}/arpl.img"
BOARD_PATH="${CONFIG_DIR}/board/arpl"

echo "Creating image file"
# Create image zeroed
dd if="/dev/zero" of="${IMAGE_FILE}" bs=1M count=4096 conv=sync 2>/dev/null
# Copy grub stage1 to image
dd if="${BOARD_PATH}/grub.bin" of="${IMAGE_FILE}" conv=notrunc,sync 2>/dev/null
# Create partitions on image
echo -e "n\np\n\n\n+128M\na\nt\n\n0b\nn\np\n\n\n+128M\nn\np\n\n\n\nw" | fdisk "${IMAGE_FILE}" >/dev/null

# Force umount, ignore errors
sudo umount "${BINARIES_DIR}/p1" 2>/dev/null || true
sudo umount "${BINARIES_DIR}/p3" 2>/dev/null || true
# Find next avaliable loop device
dev=$(sudo losetup -f)
# Setup the loop device
sudo losetup -P "$dev" "${IMAGE_FILE}"
# Format partitions
sudo mkdosfs -F32 -n ARPL1 "${dev}p1"    >/dev/null 2>&1
sudo mkfs.ext2 -F -F -L ARPL2 "${dev}p2" >/dev/null 2>&1
sudo mkfs.ext4 -F -F -L ARPL3 "${dev}p3" >/dev/null 2>&1

echo "Mounting image file"
mkdir -p "${BINARIES_DIR}/p1"
mkdir -p "${BINARIES_DIR}/p3"
sudo mount ${dev}p1 "${BINARIES_DIR}/p1"
sudo mount ${dev}p3 "${BINARIES_DIR}/p3"

echo "Copying files"
sudo cp "${BINARIES_DIR}/bzImage"            "${BINARIES_DIR}/p3/bzImage-arpl"
sudo cp "${BINARIES_DIR}/rootfs.cpio.xz"     "${BINARIES_DIR}/p3/initrd-arpl"
sudo cp -R "${BOARD_PATH}/p1/"*              "${BINARIES_DIR}/p1"
sudo cp -R "${BOARD_PATH}/p3/"*              "${BINARIES_DIR}/p3"
sync

echo "Unmount image file"
sudo umount "${BINARIES_DIR}/p1"
sudo umount "${BINARIES_DIR}/p3"
rmdir "${BINARIES_DIR}/p1"
rmdir "${BINARIES_DIR}/p3"

sudo losetup --detach $dev
