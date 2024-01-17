if [ -z ${QEMU_HOME+x} ]; then
    QEMU_SYSTEM_X86_64=qemu-system-x86_64
    QEMU_IMG=qemu-img
else
    QEMU_SYSTEM_X86_64=$QEMU_HOME/bin/qemu-system-x86_64
    QEMU_IMG=$QEMU_HOME/bin/qemu-img
fi

#QEMU_FLAGS="-cpu host -smp 4 -m 1g -display gtk,zoom-to-fit=on -enable-kvm"
#QEMU_FLAGS="-cpu host -smp 4 -m 1g -display gtk,zoom-to-fit=on -enable-kvm -netdev user,id=mynet0,hostfwd=tcp::5555-:22 -device virtio-net-pci,netdev=mynet0"
#QEMU_FLAGS="-cpu host -smp 4 -m 1g -display gtk,zoom-to-fit=on -enable-kvm -netdev user,id=mynet0,hostfwd=tcp::5555-:22 -device pcnet,netdev=mynet0"
QEMU_FLAGS="-cpu host -smp 4 -m 1g -display gtk,zoom-to-fit=on -enable-kvm -rtc base=localtime -audiodev alsa,id=snd0 -device adlib,audiodev=snd0"
QEMU_IMG_SIZE="512M"
QEMU_IMG_MOUNT_DIR="./mnt/"
# Note on the offset: https://www.cloudsavvyit.com/7517/how-to-mount-a-qemu-virtual-disk-image/
QEMU_IMG_MOUNT_OFFSET=32256
SHRINE_ISO="./Shrine-v5051.iso"
