# config/includes.chroot/

Files placed here are copied verbatim into the live filesystem's root
(`/`) during `lb build`, i.e. this tree overlays directly onto the target
system - `config/includes.chroot/etc/foo` becomes `/etc/foo` on Iron
Linux. This is where desktop config, branding, and OS identity files
belong. Nothing here has been populated yet (that's later tasks); the
directories below are pre-created as landing spots so file paths are
predictable:

| Path (relative to this dir)            | Owning task            | Purpose |
|-----------------------------------------|-------------------------|---------|
| `etc/labwc/`                            | desktop config          | Labwc `rc.xml`, `menu.xml`, `autostart`, `environment` |
| `etc/greetd/config.toml`                | desktop config          | greetd session config launching gtkgreet -> labwc |
| `etc/skel/.config/`                     | desktop config          | Per-user default configs (waybar, fuzzel, mako, foot) copied into new home dirs |
| `usr/share/backgrounds/iron/`           | branding                | Default desktop wallpaper(s), sourced from `assets/branding/wallpapers/` |
| `usr/share/plymouth/themes/iron/`       | branding / boot         | Plymouth boot splash theme, sourced from `assets/branding/plymouth/` |
| `etc/systemd/system.conf.d/`            | performance/hardening   | Any systemd defaults overrides (e.g. default target, journal limits) |
| `etc/os-release`, `etc/issue`           | OS identity              | `NAME="Iron Linux"` / `PRETTY_NAME="Iron Linux"` etc. |

Do not commit build artifacts, caches, or anything generated at build
time into this tree - only source-of-truth config files that should
ship on every install.
