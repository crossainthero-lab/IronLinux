# config/includes.chroot/

Files placed here are copied verbatim into the live filesystem's root
(`/`) during `lb build`, i.e. this tree overlays directly onto the target
system - `config/includes.chroot/etc/foo` becomes `/etc/foo` on Iron
Linux. This is where desktop config, branding, and OS identity files
belong. The Labwc desktop and greetd session defaults are now populated;
branding artwork and installer polish can keep layering files here.

| Path (relative to this dir)            | Owning task            | Purpose |
|-----------------------------------------|-------------------------|---------|
| `etc/xdg/labwc/`                        | desktop config          | System-wide Labwc `rc.xml`, `menu.xml`, `autostart`, `environment` |
| `etc/greetd/config.toml`                | desktop config          | greetd session config launching gtkgreet -> labwc |
| `etc/greetd/environments`               | desktop config          | gtkgreet session commands, led by the Iron Labwc session |
| `etc/skel/.config/`                     | desktop config          | Per-user defaults for waybar, fuzzel, mako, foot, wlogout |
| `usr/local/bin/iron-*`                  | desktop config          | Small session, screenshot, clipboard, volume, and power helpers |
| `usr/share/themes/Iron/labwc/`          | desktop config          | Iron Labwc window/menu theme |
| `usr/share/wayland-sessions/`           | desktop config          | `Iron Linux` Wayland session entry |
| `usr/share/backgrounds/iron/`           | branding                | Default desktop wallpaper(s), sourced from `assets/branding/wallpapers/` |
| `usr/share/plymouth/themes/iron/`       | branding / boot         | Plymouth boot splash theme, sourced from `assets/branding/plymouth/` |
| `etc/systemd/system.conf.d/`            | performance/hardening   | Any systemd defaults overrides (e.g. default target, journal limits) |
| `etc/os-release`, `etc/issue`           | OS identity              | `NAME="Iron Linux"` / `PRETTY_NAME="Iron Linux"` etc. |

Do not commit build artifacts, caches, or anything generated at build
time into this tree - only source-of-truth config files that should
ship on every install.
