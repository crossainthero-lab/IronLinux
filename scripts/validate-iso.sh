#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 path/to/iron-linux-amd64.iso" >&2
    exit 2
fi

ISO="$1"

fail() {
    echo "iron-linux: ISO validation failed: $*" >&2
    exit 1
}

[[ -f "$ISO" ]] || fail "not a file: $ISO"
command -v xorriso >/dev/null 2>&1 || fail "xorriso is required"

ELTORITO="$(xorriso -indev "$ISO" -report_el_torito plain 2>/dev/null)"
LISTING="$(xorriso -indev "$ISO" -find / 2>/dev/null | sed -e "s/^'//" -e "s/'$//")"

grep -Eq 'El Torito boot img.*BIOS|Pltf[[:space:]]+BIOS' <<<"$ELTORITO" || fail "missing BIOS El Torito boot image"
grep -Eq 'El Torito boot img.*UEFI|El Torito boot img.*EFI|Pltf[[:space:]]+UEFI|Pltf[[:space:]]+EFI' <<<"$ELTORITO" || fail "missing EFI El Torito boot image"

grep -q '^/live/filesystem.squashfs$' <<<"$LISTING" || fail "missing /live/filesystem.squashfs"
grep -Eq '^/live/vmlinuz($|-)' <<<"$LISTING" || fail "missing live kernel"
grep -Eq '^/live/initrd\.img($|-)' <<<"$LISTING" || fail "missing live initramfs"
grep -Eq '^/boot/grub/grub\.cfg$' <<<"$LISTING" || fail "missing GRUB configuration"
grep -Eq '^/EFI/BOOT/BOOTX64\.EFI$|^/EFI/boot/bootx64\.efi$|^/efi\.img$|^/boot/grub/efi\.img$' <<<"$LISTING" || fail "missing EFI loader image/files"

if [[ -f build.log ]]; then
    if grep -Eiq 'grub-mkimage.*usage|isohybrid: not found|error:.*grub|failed.*grub' build.log; then
        fail "build.log contains bootloader-generation errors"
    fi
fi

echo "$ELTORITO"
echo
echo "iron-linux: ISO structure validation passed for $ISO"
