# config/includes.binary/

Files placed here are copied onto the **ISO filesystem itself** (the
binary/ tree that becomes the disc image), NOT into the live Linux
filesystem. This is where bootloader splash graphics and ISO-level
branding go - things like:

- `isolinux/splash.png` - BIOS boot menu background (isolinux/syslinux)
- `boot/grub/` - GRUB theme/background for UEFI boot menu

Sourced from `assets/branding/` once that artwork exists. Left empty by
this bootstrap task; populated by the branding/boot-experience task.
