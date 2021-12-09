if [ -z ${QEMU_HOME+x} ]; then
    QEMU_SYSTEM_X86_64=qemu-system-x86_64
    QEMU_IMG=qemu-img
else
    QEMU_SYSTEM_X86_64=$QEMU_HOME/bin/qemu-system-x86_64
    QEMU_IMG=$QEMU_HOME/bin/qemu-img
fi

QEMU_FLAGS="-display gtk,zoom-to-fit=on -enable-kvm -m 512"
QEMU_IMG_SIZE="512M"
QEMU_IMG_MOUNT_DIR="./mnt/"
# Note on the offset: https://www.cloudsavvyit.com/7517/how-to-mount-a-qemu-virtual-disk-image/
QEMU_IMG_MOUNT_OFFSET=32256
SHRINE_ISO="./Shrine-v5051.iso"
