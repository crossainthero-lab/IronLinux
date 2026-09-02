# Iron Linux - Architecture

## What this is

Iron Linux is a Debian-based live/installable Linux distribution built
with Debian **live-build**. It is Debian underneath (kernel, firmware,
APT, dpkg, systemd, Mesa, PipeWire, NetworkManager, hardware support all
come straight from Debian's archive, unmodified) with a curated,
opinionated desktop stack and identity layered on top.

Iron Linux does not fork or replace any of Debian's low-level ecosystem.
`apt`, `.deb`, and third-party packages (Chrome, etc.) work exactly like
they do on any Debian machine.

## Build pipeline

```
config/package-lists/*.list.chroot  -->  lb build (debootstrap + apt)  -->  chroot filesystem
config/includes.chroot/             -->  overlaid onto that chroot verbatim
config/hooks/live/*.hook.chroot     -->  run inside that chroot (enable services, etc.)
config/includes.binary/             -->  overlaid onto the ISO/binary tree (boot splash, etc.)
                                     -->  squashfs + isolinux/grub  -->  iron-linux-amd64.iso
```

`auto/config` is the single source of truth for the `lb config`
invocation (target distribution, architecture, bootloaders, ISO
metadata). `build.sh` wraps `lb clean` / `lb config` / `lb build` and
renames the result to `iron-linux-amd64.iso`.

## Desktop stack

No desktop environment (GNOME/KDE/XFCE/Cinnamon/MATE) is used. Instead:

| Role | Choice | Why |
|---|---|---|
| Compositor | **Labwc** | Required by spec: a small, wlroots-based, Openbox-like stacking compositor. Themeable, no bundled shell/panel of its own to fight with. |
| Login manager | **greetd** + **gtkgreet** | greetd is a minimal, display-manager-agnostic Wayland login daemon; gtkgreet is a tiny GTK+layer-shell greeter we can theme directly with CSS. No seatd needed - systemd-logind (already present) provides seat/session management. |
| Panel | **waybar** | The de facto standard wlroots panel; fully CSS-themeable, modular (workspaces, clock, tray, network, audio, battery) without needing a dozen separate widgets. |
| Launcher | **fuzzel** | Minimal, fast, dmenu-like app launcher for wlroots compositors. |
| Notifications | **mako** | Small dedicated notification daemon, CSS-themeable, does one job. |
| Terminal | **foot** | Native Wayland terminal, extremely fast startup, tiny footprint, no GTK/Qt dependency. |
| File manager | **PCManFM** | Standalone GTK file manager; unlike Thunar it doesn't pull in XFCE libraries, keeping the dependency graph smaller. |
| Wallpaper | **swaybg** | The standard minimal wlroots wallpaper setter. |
| Screen lock | **swaylock** | Standard minimal wlroots screen locker, pairs with wlogout's power menu. |
| Power/logout menu | **wlogout** | Tiny layer-shell logout/power menu, CSS-themeable - this becomes Iron's custom power menu. |
| Screenshots | **grim** + **slurp** | grim captures, slurp selects a region; the standard minimal wlroots combo, nothing more needed. |
| Clipboard | **wl-clipboard** + **cliphist** | `wl-paste --watch cliphist store` keeps clipboard history alive; `wl-copy` restores selected items from the Iron launcher. |
| Polkit agent | **lxpolkit** on **polkitd** | Smallest available GTK polkit authentication agent; avoids pulling in a KDE or GNOME agent. |
| Audio | **PipeWire** + **WirePlumber** + **wob** | Modern audio/video stack per spec. Volume control is a keybinding (via labwc) calling `wpctl`, shown with `wob`'s tiny overlay bar - no full mixer GUI needed by default (users can `apt install pavucontrol` if they want one). |
| Networking | **NetworkManager** + **network-manager-applet** | `nm-applet` lives in waybar's tray, giving Wi-Fi/VPN control without a settings app. |
| Bluetooth | **BlueZ** + **blueman** | Standalone graphical Bluetooth manager, not tied to a DE. |

## Installer

**Calamares**, with `calamares-settings-debian` as the base module
configuration, re-themed for Iron in a later task. Calamares was chosen
over writing/maintaining a custom installer or wiring up `debian-installer`
because it's distribution-independent, actively maintained, already knows
how to do partitioning/bootloader/user-creation correctly, and is used by
several independent Debian-based distros already - it does the boring
disk work so Iron Linux doesn't have to.

## OS identity and branding

`/etc/os-release` (and friends) are overridden via
`config/includes.chroot/` to identify the system as Iron Linux (`NAME="Iron Linux"`,
`ID=iron`, `ID_LIKE=debian`, `LOGO=iron-linux-logo`).

Branding is unified across all stages:
- **Bootloader:** BIOS isolinux and UEFI GRUB splash (`config/includes.binary/`)
- **Boot splash:** Native Plymouth `iron` theme (`usr/share/plymouth/themes/iron/`)
- **Login screen:** greetd / gtkgreet themed with `login-background.png` and graphite CSS
- **Desktop:** Labwc session with `wallpaper-4k.png`, `lockscreen.png`, and a shared
  palette defined in `/usr/share/themes/Iron/` applied to Waybar, Fuzzel, Mako, Foot, and Wlogout.

## What's deliberately NOT here yet

The ISO has still not been built or boot-tested in this repository
workflow. Calamares installer theming and physical ISO building remain
the next follow-up layers.
