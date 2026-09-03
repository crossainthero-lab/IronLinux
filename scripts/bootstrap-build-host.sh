#!/bin/bash
# Iron Linux - build host bootstrap.
#
# Installs the tooling needed to run ./build.sh: live-build, debootstrap,
# and a handful of ISO utilities.
#
# Run this ONLY inside a disposable Debian (or Debian-derived) VM or
# container that you're happy to use exclusively for building Iron
# Linux. Do NOT run it on your daily-driver machine: installing
# live-build pulls in debootstrap and initramfs-tools as dependencies,
# which can interact with an existing initramfs generator (e.g. dracut)
# on the host and is not something you want to debug on a machine you
# rely on.
#
# Recommended: a fresh Debian stable container/VM dedicated to this repo.

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root: sudo ./scripts/bootstrap-build-host.sh" >&2
    exit 1
fi

if ! grep -qi debian /etc/os-release; then
    echo "WARNING: this doesn't look like a Debian-based system (/etc/os-release" >&2
    echo "does not mention Debian). Iron Linux's build system targets Debian" >&2
    echo "live-build specifically; continuing anyway, but expect surprises." >&2
fi

apt-get update
apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    xorriso \
    isolinux \
    syslinux-utils \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    squashfs-tools \
    ca-certificates

echo
echo "live-build tooling installed. Next: sudo ./build.sh"
