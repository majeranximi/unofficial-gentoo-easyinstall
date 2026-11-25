# Unofficial Gentoo EasyInstall (KDE)

## We made Gentoo easier to larp! 🐧

You always wanted to say *"I use Gentoo, btw"*, but the Handbook, three days of `emerge` and a kernel config
with 14,000 options got in the way. That's what this ISO is for.

**Unofficial Gentoo EasyInstall** is a live ISO that installs a ready-to-use Gentoo Linux with the KDE Plasma
desktop in a few minutes, using a normal graphical installer. You download it, write it to a USB stick and boot it,
the same way you would with Fedora or Ubuntu. Nothing is compiled during the install, the whole system is already
on the ISO, and you don't even need an internet connection.

What you end up with is **real Gentoo**, not a Gentoo-flavoured fork. It has Portage, `emerge`, USE flags, OpenRC
and the official Gentoo repository. You skip the hard part and keep all of that. If you later want to recompile the
world with `-march=native`, you can.

> ⚠️ **This is an unofficial project.** It is not made, endorsed or supported by Gentoo Linux or the
> Gentoo Foundation. "Gentoo" is a trademark of the Gentoo Foundation, Inc. Report problems with this ISO
> here, not to Gentoo. For the official installation media, see <https://www.gentoo.org/downloads/>.

## How it differs from a normal Gentoo install

| | Official Gentoo (Handbook) | Unofficial Gentoo EasyInstall |
|---|---|---|
| Installation | Manual, in a terminal, following the Handbook | Graphical installer (Calamares), a few clicks |
| Time to a working desktop | Hours (KDE compiles from source) | About 3 minutes after the installer starts |
| Internet needed to install | Yes | No (the whole system is on the ISO) |
| Result | Whatever you build | Gentoo, OpenRC, KDE Plasma 6 (Wayland), NetworkManager, Firefox |

Once installed, it is ordinary Gentoo. `emerge` works as usual. Packages come prebuilt from the
official Gentoo binhost when a matching binary exists, and are compiled locally otherwise.

## Download

**➡️ Get the ISO from the [Releases page](https://github.com/majeranximi/unofficial-gentoo-easyinstall/releases/latest).**

Each release links to the ISO (about 3.3 GB) and lists its SHA256 checksum. The ISO is larger than GitHub's 2 GiB
file limit, so it is hosted on mega.nz instead of being attached to the release. After downloading,
check that the hash matches the one in the release notes:

```bash
sha256sum unofficial-gentoo-easyinstall-kde-*.iso
```

## Requirements

- 64-bit x86 PC (x86-64), BIOS or UEFI (Secure Boot must be **off**)
- 2 GB RAM minimum, 4 GB recommended
- 15 GB disk minimum

## Installing

1. Write the ISO to a USB stick (for example with `dd`, Fedora Media Writer, Ventoy or Rufus in DD mode), or attach it to a VM.
2. Boot it. The live session logs in automatically and opens the installer. You can also use the **Install Gentoo** icon on the desktop.
3. Choose your language, time zone (detected automatically when online), keyboard, disk and user.
4. Click **Install** and wait about 3 minutes. When it finishes, reboot.

You do not need to remove the ISO afterwards. When the ISO boots and finds an installed system, its menu
starts **Boot installed Gentoo (from disk)** by default.

The live user is `gentoo` with password `gentoo`. It is removed from the installed system.

### VirtualBox

- Type: Linux / Gentoo (64-bit)
- RAM: 4096 MB, 2+ CPUs
- Display: **VMSVGA**, 128 MB video memory
- Disk: 20 GB or more
- Works with EFI enabled or disabled.

## What's inside

Gentoo stage3 `desktop-openrc` plus the `default/linux/amd64/23.0/desktop/plasma` profile:

- `gentoo-kernel-bin`, `linux-firmware` (redistributable files only)
- KDE Plasma 6 (`plasma-meta`), Konsole, Dolphin, Kate, Ark, Gwenview, Okular, Spectacle, Firefox (`firefox-bin`)
- Calamares with the Gentoo LiveCD configuration (`app-misc/calamares-gentoo-livecd`), set to copy the
  live system to disk instead of downloading a stage3
- GRUB (BIOS + UEFI), dracut, NetworkManager, SDDM

Exact package versions are in [`portage/manifest.txt`](portage/manifest.txt).

## Features

- **Graphical installer.** Calamares walks you through language, time zone, keyboard, partitioning and user
  account. Your time zone is detected automatically when you're online.
- **Your language, your keyboard.** The language, date/number formats and keyboard layout you pick are applied
  everywhere: the console, the Plasma desktop and the login screen. Typing a password with `ä`, `ł` or `é` works.
- **BIOS and UEFI.** The ISO boots on both and sets up GRUB for whichever your machine uses.
- **No need to unplug the USB stick.** When the ISO finds an installed system, its menu boots that system
  from disk by default.
- **Binary packages.** The installed system is set up to use the official Gentoo binhost, so most updates
  download prebuilt packages instead of compiling them.
- **A clean Gentoo underneath.** `make.conf` only has sensible defaults and the live-session leftovers are
  removed during the install.

## After installing

Update the system the Gentoo way. Most packages arrive as prebuilt binaries:

```bash
sudo emerge --sync
sudo emerge -avuDN @world
```

Install more software with `emerge` (for example `sudo emerge -av libreoffice-bin vlc`). If you're new to Gentoo,
the [Gentoo Wiki](https://wiki.gentoo.org/) is the best place to learn how Portage, USE flags and OpenRC work.

## Roadmap

Ideas for future releases. Nothing here is promised yet:

- 🪟 **More desktop environments to choose from**, such as **Hyprland**, GNOME, Xfce and maybe a minimal/no-desktop
  edition
- 🔒 Secure Boot support
- 🧰 VirtualBox / QEMU guest tools out of the box
- 💾 Optional swap or zram in the installer

Have an idea or found a bug? Open an [issue](https://github.com/majeranximi/unofficial-gentoo-easyinstall/issues).

## Known issues

- Secure Boot is not supported. Disable it in the firmware settings before booting the ISO.
- VirtualBox Guest Additions are not included, so there is no shared clipboard or drag and drop. Display resizing works.
- The installer offers only the KDE Plasma desktop for now (see the Roadmap).

## Building the ISO yourself (optional, for developers)

**You don't need this to use the ISO.** Download it, write it to a USB stick and boot it. This section is only
for people who want to rebuild or modify the image. You need Linux with root, about 30 GB free, `squashfs-tools`, `xorriso`, `grub` (with `i386-pc` and
`x86_64-efi` modules) and `mtools`.

```bash
# 1. stage3 + portage config
mkdir rootfs && sudo tar xpf stage3-amd64-desktop-openrc-*.tar.xz -C rootfs --xattrs-include='*.*' --numeric-owner
sudo ./chroot.sh 'emerge-webrsync && eselect profile set default/linux/amd64/23.0/desktop/plasma && getuto'
sudo mkdir -p rootfs/etc/portage/package.use && sudo cp portage/package.use rootfs/etc/portage/package.use/iso
#    add FEATURES="getbinpkg binpkg-request-signature" to rootfs/etc/portage/make.conf

# 2. packages (mostly prebuilt binaries from the Gentoo binhost)
sudo ./chroot.sh "emerge -q $(tr '\n' ' ' < portage/packages.txt)"

# 3. live configuration + ISO
sudo cp -r calamares setup-live.sh rootfs/root/
sudo ./chroot.sh /root/setup-live.sh
sudo ./make-iso.sh
```

| File | Purpose |
|---|---|
| `chroot.sh` | Mounts `/proc`, `/sys`, `/dev`, `/run` and runs a command inside `rootfs/` |
| `setup-live.sh` | Live user, autologin, language, services, Calamares config, live initramfs |
| `make-iso.sh` | squashfs + GRUB hybrid ISO + SHA256 |
| `calamares/` | Overrides for the Gentoo Calamares config (copy the live system, cleanup, reboot) |
| `portage/` | USE flags, package list, exact versions of the released ISO |

## Licenses

The scripts in this repository are released under the MIT license. Software inside the ISO keeps its own
licenses (GPL, LGPL, MIT, MPL and others; see `/var/db/pkg/*/*/LICENSE` on the installed system). Source code for every package
is available from Gentoo's distfiles mirrors. [`portage/manifest.txt`](portage/manifest.txt) lists the exact versions.
