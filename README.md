# Iron Linux

A lightweight, Debian-based Linux distribution: Wayland + Labwc, built
with Debian `live-build`, fully compatible with normal `apt`/`.deb`
package management.

Dark iron / machined metal visual identity. No GNOME, no KDE, no XFCE,
no bundled desktop environment - a small, coherent set of native
Wayland components instead.

**Status:** build skeleton + package lists are in place. The ISO has
not been built yet - see `docs/BUILD.md` once the desktop/branding
layers land.

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

Currently near-empty on purpose - these are the landing spots for
later tasks (Labwc config, greetd config, OS identity files, boot
splash artwork). Each has its own `README.md` documenting exactly which
file goes where, so later work doesn't have to guess the layout.

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
  lists (no duplicates, no malformed lines). Passing as of this commit.
- The `lb config` flags in `auto/config` were cross-checked against
  `lb config --help` on a live-build install, though the specific
  live-build version available in this dev environment is an old
  Ubuntu-packaged fork (`3.0~a57`), not the current Debian live-build
  that will actually run the build. **The flag set should be
  re-verified against `man lb_config` on the real Debian build host
  before the first real build** - see `docs/BUILD.md` and the note at
  the top of `auto/config`.

## Known limitations / not done yet

This task deliberately stops at the build skeleton. Not yet done
(tracked as later tasks in the same pipeline):

- No ISO has been built or boot-tested.
- `config/includes.chroot` has no actual Labwc/greetd/waybar/mako/foot
  config yet - just the directory layout and a README mapping intended
  file locations.
- No OS identity files (`/etc/os-release` etc.) yet.
- No branding wired into the build (source artwork is being generated
  separately under `assets/branding/`; nothing there is referenced by
  `config/` yet).
- No Calamares theming yet (default `calamares-settings-debian` look).
- Firmware package names in `core.list.chroot` are best-effort and
  should be confirmed with `apt-cache search` on the real Debian build
  host - see `docs/PACKAGES.md`.

## Using Iron Linux like Debian (once built)

```bash
sudo apt update
sudo apt install git
sudo apt install firefox-esr        # already the default browser
sudo apt install ./google-chrome-stable_current_amd64.deb
```

No Iron-specific package repository is used - Debian's own repositories
(`main contrib non-free non-free-firmware`) are the only APT sources.
