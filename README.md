# Iron Linux

### Ingot — a desktop designed to make more of your computer.

**Iron Linux is an attempt to rethink what a personal Linux desktop should feel like.** Not another distribution that changes the wallpaper, swaps a panel and calls it a new operating system. The aim is to build a coherent desktop where appearance, performance, everyday usability and user control are treated as parts of the same problem.

**Ingot** is the name of that desktop direction.

A computer should be able to feel beautifully finished without needing excessive hardware to draw its interface. It should be welcoming when you open it for the first time and remain useful when you want to change every part of it. It should be as comfortable for ordinary tasks as it is for development, creation and serious multitasking.

That is the standard Iron Linux is being built toward. **It is a direction, not a claim that the current prototype has already achieved it.**

> **Project status:** Iron Linux is in development. This repository currently contains an earlier **Debian + Labwc** live/installable prototype with a QEMU-tested installation path. The newer **Ingot** direction — a deeply integrated, GNOME-based desktop built on an Ubuntu/Debian-family foundation — is not yet implemented in this branch. [See what exists today](#where-the-project-stands).

## Why Iron Linux exists

A familiar compromise keeps appearing in desktop computing: make an interface expressive and feature-rich, and it often gets heavier; strip it down to save resources, and it can start feeling unfinished.

Iron Linux is built around rejecting that trade-off as a design rule.

Lightweight should not mean bare. A well-considered desktop still needs excellent window management, clear settings, thoughtful defaults, working hardware, accessibility, dependable updates and the freedom to run the software you actually use. Likewise, beautiful should not mean filling every interaction with effects that add latency or waste battery.

The project asks a different question: **what would a desktop look and feel like if every visual choice also had to justify its performance cost, and every performance optimisation had to preserve the experience?**

It is not trying to be the smallest distribution on a chart. It is trying to make the resources inside a real computer count.

## The idea behind Ingot

An ingot is raw metal made ready for shaping. The name fits the approach: use the strength of an established Linux foundation, then deliberately shape the experience around it.

Ingot is envisioned as more than a theme or a collection of extensions. It is the *desktop experience* of Iron Linux: the shell, interaction patterns, visual language, window behaviour, system surfaces and default workflows treated as one product.

The goal is a desktop that feels intentional from login to shutdown. Its panel, application launching, multitasking, notifications, settings, window controls and transitions should behave like they were designed together — because they were. Nothing should exist merely to fill space or make a screenshot look busier.

That does **not** mean throwing away mature Linux technology just to make every component proprietary to Iron. It means choosing a dependable foundation, improving the parts that shape the user experience, and keeping standard Linux tools available underneath.

### A visual experience with engineering behind it

Ingot's visual ambition is high: fluid motion, carefully considered depth and spacing, smooth transitions, legible typography, consistent surfaces and a desktop that feels alive without being distracting.

But effects are not the product. **Responsiveness is.** Animation should clarify where something went, what changed and what will happen next. When effects cannot run smoothly, the interface should adapt rather than force the machine to struggle.

This is a performance goal, not an announced benchmark. No unverified idle-RAM figures, frame-rate guarantees or claims about old hardware are being presented as accomplished results.

### A desktop that respects different machines

People do not all own the same hardware. Some have powerful workstations; others have modest laptops, integrated graphics, limited memory or older systems that still have years of useful life.

The ambition is for Iron Linux to make sensible choices based on the machine it is running on: preserve a consistently good experience, scale visual work appropriately, and avoid spending resources on tasks that do not benefit the user. Strong hardware should have room to shine. Modest hardware should not be treated as an afterthought.

Actual hardware-adaptive behaviour, profiles and performance targets will need implementation and repeatable testing. **They are part of the design brief, not features already shipped.**

### A computer you can actually use

A minimal default installation is only valuable if it leaves you with a capable computer.

Ingot is being designed for browsing, work, files, media, programming, creative tools, games and everyday multitasking — not for admiring an empty desktop. The intention is to ship sensible essentials, avoid unnecessary bundled applications, and let users choose the rest.

That also means staying connected to the wider Linux ecosystem. A distinct interface should not require a distinct, incompatible way of installing software or managing the machine. Standard package management, compatibility and repairability matter more than inventing a closed ecosystem.

### An experience you can make your own

A polished default is a starting point, not a restriction. Iron Linux should offer a coherent experience out of the box while leaving users free to rearrange workflows, choose applications, adjust appearance and reach the underlying Linux system.

The project is opinionated about the defaults, **not about what users are allowed to do afterward**.

## How we intend to build it

The emerging Ingot direction centres on a tailored GNOME-based desktop with an Ubuntu/Debian-family, APT-compatible foundation. The priority is to make the desktop itself excellent before expanding into experimental packaging systems, broad hardware promises or unnecessary platform complexity.

Work is guided by a few practical standards:

- **Design and performance are one discipline.** UI choices must be evaluated for input latency, animation smoothness, memory, CPU/GPU use and power consumption — not just appearance.
- **Cohesion beats a pile of features.** Fewer, better-integrated behaviours are preferable to disconnected widgets, duplicate settings and half-finished additions.
- **Build on foundations that already work.** Preserve the value of Linux, upstream security updates, standard packages and established hardware support.
- **Make the default approachable, keep the system inspectable.** A newcomer should not need a terminal to do ordinary tasks; an experienced user should never lose access to one.
- **Test claims on actual machines.** Visual polish, stability, performance and compatibility must eventually be demonstrated across different hardware, not inferred from a virtual machine or marketing mock-up.

These are criteria for the work ahead, not a feature list for a finished release.

## Where the project stands

There are **two different things** worth separating: the Iron Linux prototype that exists in this repository, and the Ingot desktop that the project is working toward.

### What is in this repository now

The current codebase is a **Debian stable (trixie) live/installable system** assembled with Debian `live-build`. It uses **Labwc** as a lightweight Wayland compositor, with greetd/gtkgreet, Waybar, Fuzzel, Mako, Foot and other deliberately selected components. It uses standard Debian APT repositories and `.deb` packages.

This prototype is real, not just a concept:

- An AMD64 ISO has been built successfully, with BIOS and UEFI boot-image structure validated.
- In QEMU using **BIOS boot**, the live system reached graphical login, launched its desktop and completed a Calamares installation to a virtual disk.
- The installed system then booted from that disk, logged in successfully and ran `sudo apt update` against Debian repositories.
- Raspberry Pi 4 ARM64 image-building tooling is present, but a physical Pi 4 has **not** been validated.

The working Labwc prototype is an engineering foundation and an earlier design direction. **It should not be mistaken for a completed Ingot desktop.**

### What has not been demonstrated

The GNOME-based Ingot interface, its planned integrated shell experience and hardware-adaptive behaviour are **not implemented in this repository's current main branch**. No production-ready Ingot release, universal hardware-compatibility claim or independently measured performance advantage is being asserted here.

The existing install path has not been end-to-end tested on physical PCs. UEFI has been structurally checked but not exercised through the complete live-login/install/reboot workflow. Real GPU drivers, laptop suspend, Bluetooth hardware, dual-boot, encryption and a broad range of storage configurations require further testing.

This distinction is intentional: the README should communicate the ambition **and** allow someone to judge the engineering honestly.

## Explore the current prototype

Experimental builds and checksums, when published, are available from [GitHub Releases](https://github.com/crossainthero-lab/IronLinux/releases). These builds represent the older Labwc-based prototype, **not an Ingot release**.

| Image | Intended target | Validation |
| --- | --- | --- |
| `iron-linux-amd64.iso` | x86-64 PCs and virtual machines | QEMU BIOS live boot and full install/reboot flow tested |
| `iron-linux-rpi4-arm64.img.xz` | Raspberry Pi 4 | Build validation; physical board testing pending |

Use a virtual machine or a disposable test system if you want to evaluate the current state. Do not treat these images as production-ready operating systems or install them over a working machine without backups.

The prototype's live login username is `iron` and its live password is `live`.

### Build from source

On a suitable **Debian build host** (preferably a disposable VM), follow the dependencies and preparation guidance in [docs/BUILD.md](docs/BUILD.md):

```bash
sudo ./scripts/bootstrap-build-host.sh
sudo ./build.sh
```

The build is configured through [auto/config](auto/config) and produces `iron-linux-amd64.iso` and a SHA-256 checksum. The scripts in this repository build the **existing Debian/Labwc prototype**; they are not a way to build the future GNOME-based Ingot desktop.

If you are trying the prototype, standard Debian package management remains available:

```bash
sudo apt update
sudo apt install git
```

## Inside the repository

The important entry points are:

| Path | Purpose |
| --- | --- |
| [`build.sh`](build.sh) and [`auto/`](auto/) | Reproducible live-build entry points |
| [`config/package-lists/`](config/package-lists/) | Base system, desktop, application and live image packages |
| [`config/includes.chroot/`](config/includes.chroot/) | Desktop defaults, scripts and system identity |
| [`config/hooks/`](config/hooks/) | Build-time configuration |
| [`assets/branding/`](assets/branding/) | Visual assets for the existing prototype |
| [`docs/BUILD.md`](docs/BUILD.md) | Build requirements and procedure |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Architecture of the earlier Labwc implementation |
| [`docs/PACKAGES.md`](docs/PACKAGES.md) | Why the existing prototype includes its selected packages |

The technical documents describe the **current/earlier implementation**, and may not reflect the newer Ingot plan. That plan will require its own specifications, implementation work and validation as it develops.

## What comes next

The next stage is not to add another six items to a feature list. It is to make the operating system feel like a considered whole.

That means establishing Ingot's interaction and visual system; making decisions about the GNOME foundation; building and profiling the shell experience; getting everyday workflows right; measuring resource use under real workloads; and then validating installation, graphics, input, accessibility, updates and hardware behaviour on real computers.

The order and implementation can change as the engineering reveals better answers. There is no promised release date in this document.

---

**Iron Linux is about using hardware well and treating the desktop as something worth designing properly. Ingot is the experience that idea is meant to become.**
