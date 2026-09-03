#!/bin/sh
set -eu

cd "$(dirname "$0")"

ISO="iron-linux-amd64.iso"
DISK="iron-linux-vm.qcow2"
KERNEL="chroot/binary/live/vmlinuz-6.12.94+deb13-amd64"
INITRD="chroot/binary/live/initrd.img-6.12.94+deb13-amd64"
MEMORY="${IRON_VM_MEMORY:-4096}"
CPUS="${IRON_VM_CPUS:-2}"
APPEND="boot=live config components username=iron hostname=iron-linux locales=en_US.UTF-8 keyboard-layouts=us systemd.unit=graphical.target plymouth.enable=0"

if [ ! -f "$ISO" ]; then
    echo "Missing $ISO. Build the ISO first with: sudo env IRON_DISTRIBUTION=trixie ./build.sh" >&2
    exit 1
fi

if [ ! -f "$DISK" ]; then
    qemu-img create -f qcow2 "$DISK" 20G
fi

if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    if [ -f "$KERNEL" ] && [ -f "$INITRD" ]; then
        exec qemu-system-x86_64 \
            -enable-kvm \
            -cpu host \
            -m "$MEMORY" \
            -smp "$CPUS" \
            -drive file="$DISK",format=qcow2,if=virtio \
            -cdrom "$ISO" \
            -kernel "$KERNEL" \
            -initrd "$INITRD" \
            -append "$APPEND" \
            -display gtk
    fi

    exec qemu-system-x86_64 \
        -enable-kvm \
        -cpu host \
        -m "$MEMORY" \
        -smp "$CPUS" \
        -drive file="$DISK",format=qcow2,if=virtio \
        -cdrom "$ISO" \
        -boot d \
        -display gtk
fi

if [ -f "$KERNEL" ] && [ -f "$INITRD" ]; then
    exec qemu-system-x86_64 \
        -accel tcg \
        -m "$MEMORY" \
        -smp "$CPUS" \
        -drive file="$DISK",format=qcow2,if=virtio \
        -cdrom "$ISO" \
        -kernel "$KERNEL" \
        -initrd "$INITRD" \
        -append "$APPEND" \
        -display gtk
fi

exec qemu-system-x86_64 \
    -accel tcg \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -drive file="$DISK",format=qcow2,if=virtio \
    -cdrom "$ISO" \
    -boot d \
    -display gtk
