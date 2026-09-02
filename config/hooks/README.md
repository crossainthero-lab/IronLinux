# config/hooks/

live-build hook scripts. Hooks are plain shell scripts run in a fixed
order (by filename, so prefix with a zero-padded number) at specific
points in the build:

- `*.hook.chroot`  - run **inside** the target chroot (i.e. as if run on
  the installed system itself) after packages are installed. Use for
  `systemctl enable <service>`, `update-alternatives`, creating the
  default user, generating font/icon caches, etc.
- `*.hook.binary`  - run against the assembled **binary/ISO tree**, after
  the filesystem image is built. Use for ISO-level tweaks that aren't
  plain file copies (those belong in `config/includes.binary/` instead).

## `normal/` vs `live/`

- `config/hooks/live/` - hooks that only run when building a **live**
  system (`lb config`'s default `--system live`, which is what Iron
  Linux uses). This is where Iron Linux's hooks belong.
- `config/hooks/normal/` - hooks for non-live (`--system normal`)
  builds. Not used by Iron Linux today; kept for parity/future use
  (e.g. a netboot or hdd-image variant).

## Naming convention

```
0010-enable-services.hook.chroot
0020-set-default-user.hook.chroot
0030-generate-caches.hook.chroot
```

Numbers leave room to insert steps later without renaming everything.

## Status

Empty for now. Anticipated hooks for later tasks (desktop/branding):

- Enable `NetworkManager.service`, `greetd.service`, `bluetooth.service`
- Create the default `iron` live user with sane groups (`sudo`,
  `netdev`, `audio`, `video`, `plugdev`)
- Regenerate font/icon caches after branding assets are installed
- Set the default GRUB/Plymouth theme to `iron`
