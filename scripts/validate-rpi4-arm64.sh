#!/bin/bash
# Validate a flashable Iron Linux Raspberry Pi 4 ARM64 raw image.

set -euo pipefail

IMAGE="${1:-iron-linux-rpi4-arm64.img}"
LOOP_DEV=""
TMP_DIR=""

ok() {
    printf 'OK:   %s\n' "$*"
}

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    set +e
    if [ -n "$TMP_DIR" ]; then
        mountpoint -q "$TMP_DIR/root/boot/firmware" && umount "$TMP_DIR/root/boot/firmware"
        mountpoint -q "$TMP_DIR/root" && umount "$TMP_DIR/root"
        rmdir "$TMP_DIR/root" "$TMP_DIR" 2>/dev/null || true
    fi
    if [ -n "$LOOP_DEV" ]; then
        losetup -d "$LOOP_DEV" 2>/dev/null || true
    fi
}
trap cleanup EXIT

[ "${EUID}" -eq 0 ] || fail "must be run as root so the image can be mounted read-only"
[ -f "$IMAGE" ] || fail "image not found: $IMAGE"

for cmd in sfdisk losetup partprobe blkid mount findmnt file chroot python3; do
    command -v "$cmd" >/dev/null 2>&1 || fail "missing required command: $cmd"
done

printf '== Image structure ==\n'
sfdisk -d "$IMAGE" >/tmp/iron-rpi4-sfdisk.$$ || fail "invalid partition table"
grep -q 'label: dos' /tmp/iron-rpi4-sfdisk.$$ || fail "expected MBR/dos partition table"
grep -q 'type=c' /tmp/iron-rpi4-sfdisk.$$ || fail "missing FAT32 LBA boot partition"
grep -q 'type=83' /tmp/iron-rpi4-sfdisk.$$ || fail "missing Linux root partition"
rm -f /tmp/iron-rpi4-sfdisk.$$
ok "partition table has FAT boot and Linux root partitions"

LOOP_DEV="$(losetup --read-only --find --partscan --show "$IMAGE")"
partprobe "$LOOP_DEV" || true
sleep 1

BOOT_PART="${LOOP_DEV}p1"
ROOT_PART="${LOOP_DEV}p2"
[ -b "$BOOT_PART" ] || BOOT_PART="${LOOP_DEV}1"
[ -b "$ROOT_PART" ] || ROOT_PART="${LOOP_DEV}2"
[ -b "$BOOT_PART" ] || fail "boot partition device missing"
[ -b "$ROOT_PART" ] || fail "root partition device missing"

[ "$(blkid -o value -s TYPE "$BOOT_PART")" = "vfat" ] || fail "partition 1 is not FAT/vfat"
[ "$(blkid -o value -s TYPE "$ROOT_PART")" = "ext4" ] || fail "partition 2 is not ext4"
ok "partition filesystems are vfat/ext4"

TMP_DIR="$(mktemp -d /tmp/iron-rpi4-validate.XXXXXX)"
mkdir -p "$TMP_DIR/root"
mount -o ro "$ROOT_PART" "$TMP_DIR/root"
mount -o ro "$BOOT_PART" "$TMP_DIR/root/boot/firmware"

printf '== ARM64 root filesystem ==\n'
[ "$(chroot "$TMP_DIR/root" dpkg --print-architecture)" = "arm64" ] || fail "dpkg architecture is not arm64"
file -L "$TMP_DIR/root/bin/sh" | grep -Eq 'ARM aarch64|ARM64|aarch64' || fail "/bin/sh is not an ARM64 binary"
if grep -R '^Architecture: amd64$' "$TMP_DIR/root/var/lib/dpkg/status" >/dev/null; then
    fail "amd64 package architecture found in ARM64 rootfs"
fi
ok "rootfs is arm64 and contains no amd64 dpkg packages"

printf '== Raspberry Pi boot files ==\n'
for f in config.txt cmdline.txt start4.elf fixup4.dat bcm2711-rpi-4-b.dtb vmlinuz initrd.img; do
    [ -s "$TMP_DIR/root/boot/firmware/$f" ] || fail "missing /boot/firmware/$f"
done
[ -d "$TMP_DIR/root/boot/firmware/overlays" ] || fail "missing /boot/firmware/overlays"
grep -q '^arm_64bit=1$' "$TMP_DIR/root/boot/firmware/config.txt" || fail "config.txt does not force arm64 boot"
grep -q '^dtoverlay=vc4-kms-v3d$' "$TMP_DIR/root/boot/firmware/config.txt" || fail "config.txt missing VC4 KMS overlay"
ROOT_PARTUUID="$(blkid -o value -s PARTUUID "$ROOT_PART")"
grep -q "root=PARTUUID=${ROOT_PARTUUID}" "$TMP_DIR/root/boot/firmware/cmdline.txt" || fail "cmdline.txt root PARTUUID does not match root partition"
grep -q '/boot/firmware' "$TMP_DIR/root/etc/fstab" || fail "fstab does not mount boot firmware partition"
ok "Pi firmware, kernel, initramfs, DTB, config and cmdline are present"

printf '== Iron desktop files ==\n'
for f in \
    etc/xdg/labwc/rc.xml \
    etc/xdg/labwc/autostart \
    etc/xdg/waybar/config \
    etc/greetd/config.toml \
    usr/share/themes/Iron/labwc/themerc \
    usr/share/backgrounds/iron/wallpaper-4k.png \
    usr/local/bin/iron-session; do
    [ -e "$TMP_DIR/root/$f" ] || fail "missing Iron desktop file: /$f"
done
if grep -q 'custom/install' "$TMP_DIR/root/etc/xdg/waybar/config"; then
    fail "Pi Waybar config still exposes the Calamares installer button"
fi
ok "Iron desktop configuration is present"

printf '== Labwc titlebar button actions ==\n'
python3 - "$TMP_DIR/root/etc/xdg/labwc/rc.xml" <<'PYEOF'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
mouse = root.find("mouse")
requirements = {
    "Iconify": "Iconify",
    "Maximize": "ToggleMaximize",
    "Close": "Close",
}
missing = []
for context_name, action_name in requirements.items():
    found = False
    if mouse is not None:
        for context in mouse.findall("context"):
            if context.get("name") != context_name:
                continue
            for bind in context.findall("mousebind"):
                if bind.get("button") == "Left" and bind.get("action") == "Click":
                    if any(action.get("name") == action_name for action in bind.findall("action")):
                        found = True
    if not found:
        missing.append(f"{context_name}/Left Click/{action_name}")
if missing:
    print("missing " + ", ".join(missing))
    raise SystemExit(1)
PYEOF
ok "window button click actions are present"

printf '== Required packages ==\n'
for pkg in \
    linux-image-arm64 raspi-firmware firmware-brcm80211 labwc waybar greetd gtkgreet foot pcmanfm network-manager pipewire wireplumber; do
    chroot "$TMP_DIR/root" dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q 'install ok installed' || fail "required package not installed: $pkg"
done
ok "required Pi/Iron packages are installed"

printf '\niron-linux: Raspberry Pi 4 ARM64 image validation passed\n'
