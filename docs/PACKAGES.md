# Iron Linux - package list rationale

Every package below was chosen deliberately for `config/package-lists/`.
This doc exists so nothing gets added later "just because" - if you
can't find a package's reason to exist here, it probably shouldn't be
in the default install.

Package lists are split into four files, all installed into both the
live image and (via Calamares) the installed system:

- **core.list.chroot** - kernel, firmware, init, APT, base shell tools.
  Required for *any* bootable, updatable Debian system.
- **desktop.list.chroot** - the Wayland/Labwc desktop stack. See the
  table in `docs/ARCHITECTURE.md` for the per-component reasoning.
- **apps.list.chroot** - the tiny default application set (browser,
  editor, archive tool).
- **live.list.chroot** - live-medium glue (live-boot/live-config/
  live-tools) and the Calamares installer.

## Notable decisions / open questions

- **`--apt-recommends true`** in `auto/config` (not `false`). The spec
  warns against accidentally pulling in a full desktop environment via
  Recommends, but also warns against breaking normal functionality by
  being trigger-happy with `--no-install-recommends`. Since the package
  set above is already hand-picked and none of the chosen components
  Recommends anything DE-sized, leaving Recommends on is the safer
  default (icon themes, mime helpers, etc. tend to arrive via Recommends
  and their absence is a common source of "why does X look/behave
  wrong" bug reports). Revisit with `apt-cache show <pkg>` on a real
  Debian host if the built image turns out heavier than expected.
- **No seatd.** greetd can use either seatd or systemd-logind for seat
  management; Iron Linux already ships systemd, so logind handles it and
  seatd would be a redundant second seat manager.
- **Firmware package names** (`firmware-linux`, `firmware-misc-nonfree`,
  `firmware-amd-graphics`, `firmware-iwlwifi`, `firmware-realtek`,
  `firmware-atheros`, `firmware-sof-signed`) are based on current Debian
  packaging knowledge but were **not** verified against a live Debian
  archive from this environment (see README's "Known limitations"). Run
  `scripts/lint-package-lists.sh` for structural sanity, but the first
  real `lb build` on an actual Debian host is what will catch a renamed
  or removed firmware package - fix names there if `lb build` reports
  a missing package.
- **Text editor: mousepad, not gedit/nano-only/leafpad.** mousepad is a
  small standalone GTK3 editor; it pulls a couple of small libxfce4
  libraries but not XFCE itself, which is an acceptable trade for a
  proper GUI editor without GNOME's stack.
- **Archive manager: xarchiver, not file-roller.** file-roller pulls
  GNOME/Nautilus integration libraries; xarchiver is a standalone GTK
  frontend with no DE affinity.
- **Volume control has no default GUI mixer app.** `pamixer` (CLI) +
  `wob` (tiny overlay bar), driven by labwc keybindings, is the default
  interaction model. `pavucontrol` is intentionally left out of the
  default install (users can `apt install pavucontrol`) to avoid
  shipping two ways to do the same thing.
