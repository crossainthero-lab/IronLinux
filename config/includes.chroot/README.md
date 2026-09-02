# config/includes.chroot/

Files placed here are copied verbatim into the live filesystem's root
(`/`) during `lb build`, i.e. this tree overlays directly onto the target
system - `config/includes.chroot/etc/foo` becomes `/etc/foo` on Iron
Linux. This is where desktop config, branding, and OS identity files
belong.

| Path (relative to this dir)            | Status | Purpose |
|-----------------------------------------|--------|---------|
| `etc/xdg/labwc/`                        | done   | System-wide Labwc `rc.xml`, `menu.xml`, `autostart`, `environment` |
| `etc/greetd/config.toml`                | done   | greetd session config launching gtkgreet -> labwc |
| `etc/greetd/environments`               | done   | gtkgreet session commands, led by the Iron Labwc session |
| `etc/greetd/style.css`                  | done   | gtkgreet CSS styling wired to login-background.png & Iron theme colors |
| `etc/skel/.config/`                     | done   | Per-user defaults for waybar, fuzzel, mako, foot, wlogout |
| `etc/xdg/`                              | done   | System-wide fallback configs for waybar, fuzzel, mako, foot, wlogout |
| `usr/local/bin/iron-*`                  | done   | Session, screenshot, clipboard, volume, and power helpers |
| `usr/share/themes/Iron/`                | done   | Shared color palette (`colors.css`, `theme.conf`) and Labwc `themerc` |
| `usr/share/wayland-sessions/`           | done   | `Iron Linux` Wayland session desktop entry with `iron-linux-logo` icon |
| `usr/share/backgrounds/iron/`           | done   | Default desktop wallpaper (`wallpaper-4k.png`), login background, and lock screen |
| `usr/share/plymouth/themes/iron/`       | done   | Plymouth boot splash theme (`iron.plymouth`, `iron.script`, `plymouth-splash.png`) |
| `usr/share/iron-linux/branding/`        | done   | Canonical SVG/PNG vector & raster branding assets on target system |
| `usr/share/pixmaps/`, `icons/hicolor/`  | done   | System logo icons matching `LOGO=iron-linux-logo` in `os-release` |
| `usr/lib/os-release`, `etc/os-release`  | done   | `NAME="Iron Linux"` / `ID=iron` / `ID_LIKE=debian` OS identity |

Do not commit build artifacts, caches, or anything generated at build
time into this tree - only source-of-truth config files that should
ship on every install.
