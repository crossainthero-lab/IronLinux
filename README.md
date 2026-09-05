# Iron Linux

A lightweight, Debian-based Linux distribution: Wayland + Labwc, built
with Debian `live-build`, fully compatible with normal `apt`/`.deb`
package management.

Dark iron / machined metal visual identity. No GNOME, no KDE, no XFCE,
no bundled desktop environment - a small, coherent set of native
Wayland components instead.

**Status:** builds a working, boot-tested ISO. As of this commit, the full
flow **boot → graphical login → Labwc desktop with a working panel →
window management → Calamares installer → real install → reboot from
disk → graphical login on the installed system → `apt update`** has been
exercised end-to-end in QEMU (BIOS boot, virtio disk/net) - see
"What's actually been tested" below for exactly what that covered and
what it didn't.

## Downloads

Prebuilt images are published on the
[GitHub Releases](https://github.com/crossainthero-lab/IronLinux/releases/latest)
page, each with a matching `.sha256` checksum.

### PC — AMD64

**Iron Linux AMD64 ISO** — for standard x86-64 PCs, laptops and virtual
machines. Boot it directly, or use it with the bundled Calamares
installer to install to disk.

→ GitHub Releases → `iron-linux-amd64.iso`

### Raspberry Pi 4 — ARM64

**Iron Linux Raspberry Pi 4 ARM64** — a compressed, flashable raw disk
image. Decompress before flashing, or use an imaging tool (e.g. Raspberry
Pi Imager, `balenaEtcher`) that can flash `.xz` images directly.

→ GitHub Releases → `iron-linux-rpi4-arm64.img.xz`

Build validated; physical Raspberry Pi 4 hardware validation pending.

The full uncompressed Raspberry Pi `.img` (~8 GB) is not distributed
through GitHub Releases due to size; it is archived separately.

## Quick start

```bash
# One-time, on a disposable Debian VM/container (see docs/BUILD.md):
sudo ./scripts/bootstrap-build-host.sh

# Build:
sudo ./build.sh
```

Produces `iron-linux-amd64.iso` in the repo root, plus a `.sha256`
checksum.

## Repository layout

```
.
├── build.sh                     Top-level build entry point (clean/config/build -> ISO)
├── auto/                        live-build "auto scripts" convention
│   ├── config                     The canonical `lb config` invocation (source of truth)
│   ├── build                      Thin `lb build` wrapper (logs to build.log)
│   └── clean                      Thin `lb clean` wrapper
├── config/                      live-build configuration
│   ├── package-lists/              What gets installed (see below)
│   ├── includes.chroot/            Files overlaid onto the live/installed filesystem
│   ├── includes.binary/            Files overlaid onto the ISO/boot media itself
│   └── hooks/                      Build-time scripts (service enablement, etc.)
│       ├── live/                     Hooks for the live system build (Iron Linux uses this)
│       └── normal/                   Hooks for non-live builds (unused today)
├── scripts/                     Helper scripts (host bootstrap, list linting)
├── assets/branding/             Source artwork (logo, wordmark, wallpapers, plymouth, ...)
└── docs/                        Architecture, package rationale, detailed build docs
```

### Package lists (`config/package-lists/`)

| File | Contents |
|---|---|
| `core.list.chroot` | Kernel, firmware, systemd, APT tooling, base shell utilities |
| `desktop.list.chroot` | Labwc + the full Wayland desktop stack (panel, launcher, notifications, terminal, file manager, audio, network, bluetooth) |
| `apps.list.chroot` | Firefox ESR, a text editor, archive tools - deliberately minimal |
| `live.list.chroot` | live-boot/live-config/live-tools + the Calamares installer |

Full rationale for every package choice: `docs/PACKAGES.md`.
Desktop component reasoning and build pipeline: `docs/ARCHITECTURE.md`.

### `config/includes.chroot/` and `config/includes.binary/`

`config/includes.chroot/` now contains the system-wide Labwc session,
greetd/gtkgreet wiring, Waybar/Fuzzel/Mako/Foot/Wlogout defaults, and
small Iron helper scripts. Branding artwork and boot media assets still
belong in `config/includes.chroot/` and `config/includes.binary/` as
they are generated.

## Build system choice

**Debian live-build**, per project requirements. `auto/config` holds the
full `lb config` invocation as a committed script (live-build's own
convention: `lb config` auto-executes `auto/config` if present), so the
entire build configuration is reproducible from a clean checkout - no
manually-run, undocumented `lb config --flag ...` commands.

Target: Debian **stable**, **amd64**, ISO-hybrid (BIOS + UEFI bootable,
also `dd`-able to a USB stick).

## What's already validated

- `./scripts/lint-package-lists.sh` - structural check of the package
  lists (no duplicates, no malformed lines).
- `./scripts/validate-desktop-config.sh` - pre-build sanity checks: XML
  well-formedness (rc.xml/menu.xml), GTK-CSS syntax (waybar/wlogout
  stylesheets - GTK's CSS engine is a small subset of real CSS and has
  no error recovery for a bad selector or an unbalanced comment), Waybar
  JSON validity, every Iron helper script's executable bit and
  interpreter, every referenced command's owning package, and the
  Calamares module sequence (duplicate modules, module ids with no
  corresponding `.conf`/`module.desc`). Run it before spending ~10
  minutes on a build.
- A full ISO build (`sudo ./build.sh`) on the current Debian
  **trixie/stable** `live-build` (20250814) completes successfully and
  passes BIOS+UEFI El Torito structural validation.

### What's actually been tested (QEMU, BIOS boot, virtio disk/net)

- Live boot to a graphical greetd/gtkgreet login, login as the live
  `iron` user (live-config's default password is **`live`**, not
  blank - undocumented anywhere in the UI, so noting it here).
- Labwc session: Waybar panel (launcher, workspaces, taskbar, clock,
  tray, network, bluetooth, volume, power), Fuzzel launcher, Foot
  terminal, PCManFM, window decorations (server-side, Iron theme),
  Alt+F4 close, Alt+Tab, double-click-to-maximize, keyboard shortcuts.
- No spurious "failed to mount" notification on boot.
- Calamares: launches with no initialization error, no duplicate
  timezone module, no blank page; Welcome → Location → Keyboard →
  Partitions → Users → Summary → Install → Finish, matching the
  intended flow.
- A real install to a blank 20GB virtio disk, completing successfully
  end to end (partitioning, unpacking, users, displaymanager, grub,
  package cleanup all confirmed to actually finish, not just start).
- Shutdown, ISO detached, cold boot from the installed disk: GRUB (BIOS)
  boots the installed system, graphical greetd/gtkgreet login appears,
  login works, full desktop (panel, launcher, terminal, window
  management) works exactly as on the live system, `/etc/os-release`
  correctly identifies Iron Linux, and `sudo apt update` succeeds
  against the real Debian mirrors.

### Not tested

- Real hardware of any kind - everything above is QEMU/KVM only.
  Firmware package coverage (`core.list.chroot`) is best-effort and
  unverified against actual devices.
- UEFI boot end-to-end (the ISO's UEFI El Torito image is structurally
  validated, but the full login→install→reboot flow above was only
  driven through the BIOS path).
- Manual partitioning, LUKS/encrypted installs, multi-disk or dual-boot
  scenarios, Bluetooth with real hardware, suspend/resume.
- Precise mouse-click behavior on Labwc's own server-side-decoration
  titlebar buttons and on some Qt/XWayland widgets could not be
  confirmed via the QEMU synthetic-input harness used for this testing
  (clicks that only need "hover" or "press" registered fine; clicks
  requiring a matched press+release on those specific widgets did not,
  across repeated attempts) - keyboard equivalents (Alt+F4, Super+H,
  Super+Up/Down, and double-click-to-maximize on the titlebar) were all
  confirmed to work reliably instead. This needs verification with a
  real mouse before being called resolved either way.

## Known limitations / not done yet

- Calamares installer theming is functional but minimal (Iron branding
  + a corrected module sequence; visual polish beyond that is not done).
- Firmware package names in `core.list.chroot` are best-effort and
  should be confirmed with `apt-cache search` on real target hardware.

## Using Iron Linux like Debian (once built)

```bash
sudo apt update
sudo apt install git
sudo apt install firefox-esr        # already the default browser
sudo apt install ./google-chrome-stable_current_amd64.deb
```

No Iron-specific package repository is used - Debian's own repositories
(`main contrib non-free non-free-firmware`) are the only APT sources.
