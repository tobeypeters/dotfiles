#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: ./install2.sh <shrineos.img>"
    echo "ERROR: no path to image is provided"
    exit 1
fi

set -xe

. ./config.sh

$QEMU_IMG create "$1" $QEMU_IMG_SIZE
$QEMU_SYSTEM_X86_64 $QEMU_FLAGS -cdrom Shrine-v5051.iso -hda "$1" -boot d
