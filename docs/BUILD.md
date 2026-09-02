# Iron Linux - build instructions (detail)

See the root `README.md` for the quick version. This doc covers the
"why" and troubleshooting.

## Build host requirements

- A Debian (or close Debian derivative) machine, VM, or container.
  live-build is Debian-specific tooling; running it elsewhere is
  unsupported.
- Root access (live-build needs to chroot, bind-mount, and manipulate
  device nodes).
- ~15-20 GB free disk (chroot + cache + squashfs + final ISO).
- Network access to Debian's mirrors during the build.

**Use a disposable VM or container, not your everyday machine.**
`apt install live-build` pulls in `debootstrap` and touches
initramfs-related packages; keep that blast radius off a machine you
depend on.

## One-time setup

```bash
sudo ./scripts/bootstrap-build-host.sh
```

Installs `live-build`, `debootstrap`, and the ISO tooling (`xorriso`,
`isolinux`, `syslinux-efi`, `grub-efi-amd64-bin`, `squashfs-tools`, ...).

## Building

```bash
sudo ./build.sh
```

This runs, in order:

1. `lb clean --purge` - wipe any previous build state.
2. `lb config` - regenerate `config/{bootstrap,chroot,binary,common,source}`
   from `auto/config` (these generated directories are gitignored -
   only `auto/config` itself is committed).
3. `lb build` - debootstrap the base system, install the package lists,
   overlay `config/includes.chroot`, run `config/hooks/live/*.hook.chroot`,
   assemble the squashfs + ISO, overlay `config/includes.binary`.
4. Rename the resulting image to `iron-linux-amd64.iso` and write a
   `.sha256` checksum next to it.

Useful flags:

- `./build.sh --no-clean` - skip step 1 for a faster incremental rebuild
  (only safe if the package lists/config haven't changed structurally).
- `./build.sh --config-only` - just run `lb config`, useful for checking
  the generated config without a full build.
- `./build.sh --clean-only` - just wipe build state.

## Validating package lists without a full build

```bash
./scripts/lint-package-lists.sh
```

Catches duplicate/malformed entries. Does not hit the network or
require live-build - safe to run anywhere, including this dev
environment.

## If `lb build` fails

- **"Couldn't find package X"** - a package name in
  `config/package-lists/*.list.chroot` is wrong or was renamed/removed
  in the target Debian release. Check `apt-cache search <topic>` on the
  build host and fix the list. `docs/PACKAGES.md` documents which
  package names are best-effort and worth checking first (mainly the
  `firmware-*` set).
- **Stuck mounts after a failed build** - `sudo lb clean --purge` should
  unmount and remove `chroot/`; if it doesn't, check `mount | grep
  $(pwd)/chroot` and `umount` manually before retrying.
- **Out of disk space** - `lb build` needs the chroot, the APT cache
  under `cache/`, and the final squashfs simultaneously; make sure the
  build host has enough free space (see requirements above).

## After a successful build

Boot-test `iron-linux-amd64.iso` in a VM before trusting it:

```bash
qemu-system-x86_64 -m 4096 -enable-kvm \
  -cdrom iron-linux-amd64.iso \
  -boot d
```

See the root `README.md`'s testing checklist for what to verify once it
boots.
