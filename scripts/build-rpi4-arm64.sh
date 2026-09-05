#!/bin/bash
# Build a flashable Iron Linux ARM64 image for Raspberry Pi 4.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SUITE="${IRON_RPI4_SUITE:-trixie}"
MIRROR="${IRON_RPI4_MIRROR:-http://deb.debian.org/debian}"
IMAGE_NAME="${IRON_RPI4_IMAGE_NAME:-iron-linux-rpi4-arm64.img}"
IMAGE_SIZE_MB="${IRON_RPI4_IMAGE_SIZE_MB:-8192}"
BOOT_SIZE_MB="${IRON_RPI4_BOOT_SIZE_MB:-512}"
BUILD_DIR="${IRON_RPI4_BUILD_DIR:-$ROOT_DIR/build/rpi4-arm64}"
ROOTFS="$BUILD_DIR/rootfs"
BOOT_STAGING="$BUILD_DIR/boot"
MNT_ROOT="$BUILD_DIR/mnt-root"
MNT_BOOT="$BUILD_DIR/mnt-boot"
IMAGE="$ROOT_DIR/$IMAGE_NAME"
CHECKSUM="$IMAGE.sha256"
DISK_ID="${IRON_RPI4_DISK_ID:-a14b4c01}"
ROOT_PARTUUID="${DISK_ID}-02"

LOOP_DEV=""
MOUNTS=()

log() {
    printf '\n\033[1;36m[iron-rpi4]\033[0m %s\n' "$*"
}

fail() {
    printf '\n\033[1;31m[iron-rpi4] ERROR:\033[0m %s\n' "$*" >&2
    exit 1
}

cleanup() {
    set +e
    for ((i=${#MOUNTS[@]}-1; i>=0; i--)); do
        mountpoint -q "${MOUNTS[$i]}" && umount "${MOUNTS[$i]}"
    done
    if [ -n "$LOOP_DEV" ]; then
        losetup -d "$LOOP_DEV" 2>/dev/null || true
    fi
}
trap cleanup EXIT

require_root() {
    [ "${EUID}" -eq 0 ] || fail "must be run as root. Try: sudo ./scripts/build-rpi4-arm64.sh"
}

require_commands() {
    missing=0
    for cmd in debootstrap chroot sfdisk losetup partprobe mkfs.vfat mkfs.ext4 blkid rsync findmnt xz sha256sum; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'missing required command: %s\n' "$cmd" >&2
            missing=1
        fi
    done
    if ! [ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ] && ! command -v qemu-aarch64 >/dev/null 2>&1; then
        printf 'missing ARM64 userspace emulation: install qemu-user-binfmt or qemu-user-static\n' >&2
        missing=1
    fi
    [ "$missing" -eq 0 ] || fail "install missing build dependencies and retry"
}

read_package_list() {
    awk '
        /^[[:space:]]*($|#)/ { next }
        { sub(/[[:space:]]*#.*/, ""); print }
    ' "$@"
}

chroot_run() {
    chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive PATH=/usr/sbin:/usr/bin:/sbin:/bin "$@"
}

apt_get() {
    chroot_run apt-get \
        -o Dpkg::Options::=--force-confdef \
        -o Dpkg::Options::=--force-confold \
        "$@"
}

mount_chroot_fs() {
    mountpoint -q "$ROOTFS/proc" || { mount -t proc proc "$ROOTFS/proc"; MOUNTS+=("$ROOTFS/proc"); }
    mountpoint -q "$ROOTFS/sys" || { mount --rbind /sys "$ROOTFS/sys"; mount --make-rslave "$ROOTFS/sys"; MOUNTS+=("$ROOTFS/sys"); }
    mountpoint -q "$ROOTFS/dev" || { mount --rbind /dev "$ROOTFS/dev"; mount --make-rslave "$ROOTFS/dev"; MOUNTS+=("$ROOTFS/dev"); }
}

copy_iron_config() {
    log "Overlaying shared Iron desktop configuration"
    rsync -a --chown=0:0 \
        --exclude='/etc/calamares' \
        --exclude='/usr/lib/calamares' \
        --exclude='/usr/share/calamares' \
        --exclude='/usr/bin/calamares-install-debian' \
        --exclude='/usr/bin/calamares-install-iron' \
        --exclude='/usr/local/bin/iron-installer' \
        --exclude='/usr/share/applications/calamares-install-debian.desktop' \
        --exclude='/usr/share/applications/iron-installer.desktop' \
        --exclude='/etc/skel/Desktop/install-iron-linux.desktop' \
        config/includes.chroot/ "$ROOTFS/"

    rsync -a --chown=0:0 config/rpi4-arm64/includes.chroot/ "$ROOTFS/"
    chmod 0755 "$ROOTFS/usr/local/sbin/iron-rpi4-firstboot"
}

configure_rootfs() {
    log "Configuring root filesystem"
    cat > "$ROOTFS/etc/apt/sources.list" <<EOF
deb $MIRROR $SUITE main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${SUITE}-security main contrib non-free non-free-firmware
deb $MIRROR ${SUITE}-updates main contrib non-free non-free-firmware
EOF

    cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
    printf 'iron-linux\n' > "$ROOTFS/etc/hostname"
    cat > "$ROOTFS/etc/hosts" <<'EOF'
127.0.0.1 localhost
127.0.1.1 iron-linux

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    cat > "$ROOTFS/etc/fstab" <<EOF
PARTUUID=${DISK_ID}-01  /boot/firmware  vfat  defaults,flush  0  2
PARTUUID=${ROOT_PARTUUID}  /  ext4  defaults,noatime  0  1
EOF

    printf '%s\n' 'en_US.UTF-8 UTF-8' > "$ROOTFS/etc/locale.gen"
    printf '%s\n' 'LANG=en_US.UTF-8' > "$ROOTFS/etc/default/locale"

    mkdir -p "$ROOTFS/etc/apt/apt.conf.d"
    cat > "$ROOTFS/etc/apt/apt.conf.d/99iron-rpi4" <<'EOF'
APT::Install-Recommends "true";
Acquire::Languages "none";
EOF

    cat > "$ROOTFS/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
    chmod 0755 "$ROOTFS/usr/sbin/policy-rc.d"
}

install_packages() {
    log "Installing ARM64 Iron package set"
    local pkgs
    pkgs="$(read_package_list \
        config/rpi4-arm64/package-lists/core.list \
        config/rpi4-arm64/package-lists/desktop.list \
        config/rpi4-arm64/package-lists/apps.list)"

    mount_chroot_fs
    apt_get update
    apt_get -y dist-upgrade
    apt_get install -y $pkgs
    copy_iron_config

    chroot_run locale-gen
    for group in sudo audio video input plugdev netdev bluetooth; do
        chroot_run getent group "$group" >/dev/null 2>&1 || chroot_run groupadd --system "$group"
    done
    if ! chroot_run id iron >/dev/null 2>&1; then
        chroot_run useradd -m -s /bin/bash -G sudo,audio,video,input,plugdev,netdev,bluetooth iron
    fi
    printf 'iron:live\n' | chroot "$ROOTFS" chpasswd
    chroot_run passwd -l root >/dev/null || true

    chroot_run systemctl set-default graphical.target
    chroot_run systemctl enable NetworkManager.service
    chroot_run systemctl enable greetd.service
    chroot_run systemctl enable bluetooth.service
    chroot_run systemctl enable iron-rpi4-firstboot.service
    chroot_run systemctl mask NetworkManager-wait-online.service >/dev/null || true

    if [ -f "$ROOTFS/usr/share/plymouth/themes/iron/iron.plymouth" ]; then
        chroot_run update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/iron/iron.plymouth 200 || true
        chroot_run update-alternatives --set default.plymouth /usr/share/plymouth/themes/iron/iron.plymouth || true
    fi
    chroot_run update-initramfs -u -k all

    rm -f "$ROOTFS/usr/sbin/policy-rc.d"
    truncate -s 0 "$ROOTFS/etc/machine-id" || true
    rm -f "$ROOTFS/var/lib/dbus/machine-id"
}

stage_boot_files() {
    log "Staging Raspberry Pi firmware and ARM64 kernel"
    mkdir -p "$BOOT_STAGING"
    rsync -a "$ROOTFS/usr/lib/raspi-firmware/" "$BOOT_STAGING/"

    local kernel_version dtb_dir
    kernel_version="$(basename "$(find "$ROOTFS/boot" -maxdepth 1 -type f -name 'vmlinuz-*' | sort -V | tail -n 1)" | sed 's/^vmlinuz-//')"
    [ -n "$kernel_version" ] || fail "no ARM64 kernel was installed"

    cp "$ROOTFS/boot/vmlinuz-$kernel_version" "$BOOT_STAGING/vmlinuz"
    cp "$ROOTFS/boot/initrd.img-$kernel_version" "$BOOT_STAGING/initrd.img"

    dtb_dir="$ROOTFS/usr/lib/linux-image-$kernel_version"
    [ -d "$dtb_dir" ] || fail "missing DTB directory: /usr/lib/linux-image-$kernel_version"
    find "$dtb_dir" -name 'bcm2711-rpi-*.dtb' -exec cp {} "$BOOT_STAGING/" \;
    [ -f "$BOOT_STAGING/bcm2711-rpi-4-b.dtb" ] || fail "missing Raspberry Pi 4 Model B DTB"

    cat > "$BOOT_STAGING/config.txt" <<'EOF'
# Iron Linux Raspberry Pi 4 ARM64 boot configuration
arm_64bit=1
kernel=vmlinuz
initramfs initrd.img followkernel

# Raspberry Pi 4 KMS graphics stack
dtoverlay=vc4-kms-v3d
max_framebuffers=2
disable_overscan=1

# Basic onboard hardware
dtparam=audio=on
camera_auto_detect=1
display_auto_detect=1
enable_uart=1

[pi4]
arm_boost=1

[all]
EOF

    cat > "$BOOT_STAGING/cmdline.txt" <<EOF
console=serial0,115200 console=tty1 root=PARTUUID=${ROOT_PARTUUID} rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles
EOF
}

create_image() {
    log "Creating raw disk image: $IMAGE_NAME"
    mkdir -p "$MNT_ROOT" "$MNT_BOOT"
    truncate -s "${IMAGE_SIZE_MB}M" "$IMAGE"

    local boot_sectors
    boot_sectors=$((BOOT_SIZE_MB * 1024 * 1024 / 512))
    sfdisk "$IMAGE" <<EOF
label: dos
label-id: 0x${DISK_ID}
unit: sectors

start=2048, size=${boot_sectors}, type=c, bootable
start=$((2048 + boot_sectors)), type=83
EOF

    LOOP_DEV="$(losetup --find --partscan --show "$IMAGE")"
    partprobe "$LOOP_DEV" || true
    sleep 1

    local boot_part root_part
    boot_part="${LOOP_DEV}p1"
    root_part="${LOOP_DEV}p2"
    [ -b "$boot_part" ] || boot_part="${LOOP_DEV}1"
    [ -b "$root_part" ] || root_part="${LOOP_DEV}2"
    [ -b "$boot_part" ] || fail "boot partition device not found for $LOOP_DEV"
    [ -b "$root_part" ] || fail "root partition device not found for $LOOP_DEV"

    mkfs.vfat -F 32 -n IRON_BOOT "$boot_part"
    mkfs.ext4 -F -L IRON_ROOT "$root_part"

    mount "$root_part" "$MNT_ROOT"; MOUNTS+=("$MNT_ROOT")
    mkdir -p "$MNT_ROOT/boot/firmware"
    mount "$boot_part" "$MNT_ROOT/boot/firmware"; MOUNTS+=("$MNT_ROOT/boot/firmware")

    log "Copying root filesystem into image"
    rsync -aHAX --numeric-ids \
        --exclude='/proc/*' \
        --exclude='/sys/*' \
        --exclude='/dev/*' \
        --exclude='/run/*' \
        --exclude='/tmp/*' \
        "$ROOTFS/" "$MNT_ROOT/"

    mkdir -p "$MNT_ROOT/dev" "$MNT_ROOT/proc" "$MNT_ROOT/sys" "$MNT_ROOT/run" "$MNT_ROOT/tmp"
    chmod 1777 "$MNT_ROOT/tmp"

    log "Copying Raspberry Pi boot partition files"
    rsync -a "$BOOT_STAGING/" "$MNT_ROOT/boot/firmware/"
    sync
}

compress_image() {
    if [ "${IRON_RPI4_COMPRESS:-1}" = "1" ]; then
        log "Compressing image with xz"
        xz -T0 -f -k "$IMAGE"
        sha256sum "$IMAGE.xz" > "$IMAGE.xz.sha256"
    fi
}

main() {
    require_root
    require_commands

    log "Preparing build directory"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    log "Bootstrapping Debian $SUITE arm64 root filesystem"
    debootstrap --arch=arm64 --components=main,contrib,non-free,non-free-firmware "$SUITE" "$ROOTFS" "$MIRROR"

    copy_iron_config
    configure_rootfs
    install_packages
    stage_boot_files
    rm -f "$IMAGE" "$IMAGE.xz" "$CHECKSUM" "$IMAGE.xz.sha256"
    create_image

    log "Validating image"
    "$ROOT_DIR/scripts/validate-rpi4-arm64.sh" "$IMAGE"

    sha256sum "$IMAGE" > "$CHECKSUM"
    compress_image

    log "Done. Output: $IMAGE"
    log "Checksum:   $(cat "$CHECKSUM")"
    if [ -f "$IMAGE.xz" ]; then
        log "Compressed: $IMAGE.xz"
        log "XZ checksum: $(cat "$IMAGE.xz.sha256")"
    fi
}

main "$@"
