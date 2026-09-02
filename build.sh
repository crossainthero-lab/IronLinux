#!/bin/bash
# Iron Linux - top-level build entry point.
#
# Wraps `lb clean` / `lb config` / `lb build` and produces
# iron-linux-amd64.iso in the repository root.
#
# Usage:
#   ./build.sh                Full build (clean + config + build)
#   ./build.sh --no-clean      Skip `lb clean` (faster incremental rebuild)
#   ./build.sh --clean-only    Just clean build state and exit
#   ./build.sh --config-only   Just (re)run lb config and exit
#
# This script MUST be run as root (live-build needs root to chroot,
# mount, and manipulate device nodes), on a Debian or Debian-derived
# build host with the `live-build` package installed.
#
# IMPORTANT: build inside a disposable VM or container, not on a machine
# you care about. `apt install live-build` pulls in debootstrap and can
# interact with your host's initramfs generator; running the actual
# `lb build` chroot/mount operations on your everyday machine is not
# recommended even though live-build tries to keep them contained under
# ./chroot. See docs/BUILD.md.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="iron-linux-amd64"
IMAGE_OUT="${IMAGE_NAME}.iso"
CHECKSUM_OUT="${IMAGE_OUT}.sha256"

DO_CLEAN=true
DO_CONFIG=true
DO_BUILD=true

for arg in "$@"; do
    case "$arg" in
        --no-clean)
            DO_CLEAN=false
            ;;
        --clean-only)
            DO_CONFIG=false
            DO_BUILD=false
            ;;
        --config-only)
            DO_CLEAN=false
            DO_BUILD=false
            ;;
        -h|--help)
            awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
            exit 0
            ;;
        *)
            echo "iron-linux: unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

log() {
    printf '\n\033[1;36m[iron-linux]\033[0m %s\n' "$1"
}

fail() {
    printf '\n\033[1;31m[iron-linux] ERROR:\033[0m %s\n' "$1" >&2
    exit 1
}

# --- Sanity checks -----------------------------------------------------

if [[ "${EUID}" -ne 0 ]]; then
    fail "must be run as root (live-build needs to chroot/mount). Try: sudo ./build.sh"
fi

if ! command -v lb >/dev/null 2>&1; then
    fail "live-build not found. Install it first: apt install live-build (see docs/BUILD.md)."
fi

if [[ ! -x auto/config ]]; then
    fail "auto/config is missing or not executable. Run: chmod +x auto/config auto/build auto/clean"
fi

# --- Clean ---------------------------------------------------------------

if $DO_CLEAN; then
    log "Cleaning previous build state (lb clean)..."
    lb clean --purge
    rm -f "${IMAGE_OUT}" "${CHECKSUM_OUT}" build.log
else
    log "Skipping clean (--no-clean given)."
fi

# --- Config ----------------------------------------------------------------

if $DO_CONFIG; then
    log "Generating live-build configuration (lb config, via auto/config)..."
    lb config
fi

if ! $DO_BUILD; then
    log "Requested config/clean only - stopping here."
    exit 0
fi

# --- Build -------------------------------------------------------------

log "Building Iron Linux (lb build). This can take a while..."
lb build 2>&1 | tee build.log

# --- Locate + rename output ---------------------------------------------

# live-build's output filename depends on live-build version and
# --binary-images setting; check the common possibilities.
CANDIDATE=""
for f in live-image-amd64.hybrid.iso live-image-amd64.iso; do
    if [[ -f "$f" ]]; then
        CANDIDATE="$f"
        break
    fi
done

if [[ -z "$CANDIDATE" ]]; then
    fail "build finished but no output ISO was found (expected live-image-amd64*.iso). Check build.log."
fi

mv -f "$CANDIDATE" "${IMAGE_OUT}"
sha256sum "${IMAGE_OUT}" > "${CHECKSUM_OUT}"

log "Done. Output: ${IMAGE_OUT}"
log "Checksum:   $(cat "${CHECKSUM_OUT}")"
