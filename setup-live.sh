#!/bin/bash
# Turns rootfs/ into the live system. Run inside the chroot: sudo ./chroot.sh /root/setup-live.sh
set -euo pipefail

# --- language: English live session; Calamares lets the user pick language/zone/keyboard for the install ---
# every supported locale listed commented out (Calamares enables the ones the user picks), en_US enabled
{ echo 'en_US.UTF-8 UTF-8'; sed 's/^/# /' /usr/share/i18n/SUPPORTED; } > /etc/locale.gen
locale-gen -q
eselect locale set en_US.utf8
echo 'keymap="us"' > /etc/conf.d/keymaps
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo 'hostname="gentoo-live"' > /etc/conf.d/hostname
rm -f /etc/X11/xorg.conf.d/00-keyboard.conf

# --- make.conf shipped to users (the build's own settings must not leak into installed systems) ---
cat > /etc/portage/make.conf <<'EOF'
# Unofficial Gentoo EasyInstall. Packages come prebuilt from the official Gentoo binhost
# (see /etc/portage/binrepos.conf); anything without a matching binary is compiled locally.
COMMON_FLAGS="-O2 -pipe"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"
LC_MESSAGES=C.UTF-8

FEATURES="getbinpkg binpkg-request-signature"
ACCEPT_LICENSE="@FREE @BINARY-REDISTRIBUTABLE"
VIDEO_CARDS="amdgpu radeonsi intel i965 iris nouveau virgl vmware qxl"
INPUT_DEVICES="libinput"
GRUB_PLATFORMS="efi-64 pc"
EOF

# --- OpenRC services ---
echo 'DISPLAYMANAGER="sddm"' > /etc/conf.d/display-manager
rc-update add dbus default
rc-update add elogind boot
rc-update add NetworkManager default
rc-update add display-manager default
rc-update add udev sysinit 2>/dev/null || true

# --- live user "gentoo" (the Gentoo Calamares modules expect this name) ---
id gentoo >/dev/null 2>&1 || useradd -m -G wheel,audio,video,usb,cdrom,plugdev,users -s /bin/bash gentoo
echo 'gentoo:gentoo' | chpasswd
passwd -l root
mkdir -p /etc/sudoers.d
echo 'gentoo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/00-live
chmod 440 /etc/sudoers.d/00-live
# Installed system: members of wheel (the installer puts the new user there) may use sudo with their password.
# The Gentoo Calamares config doesn't set sudoersGroup, so without this file sudo is refused after install.
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

# --- SDDM autologin into Plasma (Wayland; X11 session stays available in the session menu) ---
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/00-live-autologin.conf <<'EOF'
[Autologin]
User=gentoo
Session=plasma
Relogin=false
EOF

# --- SDDM: Breeze theme + the installer's keyboard layout on the login screen ---
install -Dm 755 /root/calamares/sddm-xsetup.sh /etc/sddm/Xsetup-keyboard
printf '[Theme]\nCurrent=breeze\n\n[X11]\nDisplayCommand=/etc/sddm/Xsetup-keyboard\n' > /etc/sddm.conf.d/10-easyinstall.conf

# --- installer icon on the desktop + autostart ---
D=/home/gentoo/Desktop
mkdir -p "$D" /home/gentoo/.config/autostart
install -m 755 /usr/share/applications/gentoo-installer.desktop "$D/"
install -m 644 /usr/share/applications/gentoo-installer.desktop /home/gentoo/.config/autostart/
rm -f /home/gentoo/.config/kxkbrc
cat > /home/gentoo/.config/kscreenlockerrc <<'EOF'
[Daemon]
Autolock=false
LockOnResume=false
EOF
# Plasma Welcome covered the installer and crashed on VMSVGA. Its kded module detects live sessions and
# ignores all config, so the plugin is moved aside in the live image; Calamares (shellprocess) restores it.
K=/usr/lib64/qt6/plugins/kf6/kded/kded_plasma_welcome.so
[ -f "$K" ] && mv "$K" /usr/lib64/kded_plasma_welcome.so.live-off
rm -f /home/gentoo/.local/share/applications/org.kde.plasma-welcome.desktop /home/gentoo/.config/kded6rc
chown -R gentoo:gentoo /home/gentoo

# --- Calamares: copy the prebuilt system instead of downloading stage3 and compiling ---
install -m 644 /root/calamares/settings.conf /etc/calamares/settings.conf
install -Dm 755 /root/calamares/openrc-postinstall.sh /usr/lib/easyinstall/openrc-postinstall.sh
for m in unpackfs shellprocess finished welcome; do
  install -m 644 /root/calamares/$m.conf /etc/calamares/modules/$m.conf
done
# Branding: make it obvious this is not an official Gentoo release
B=/etc/calamares/branding/gentoo_branding/branding.desc
sed -i -E \
  -e 's|^(\s*productName:).*|\1         Unofficial Gentoo EasyInstall|' \
  -e 's|^(\s*shortProductName:).*|\1    Gentoo EasyInstall|' \
  -e 's|^(\s*versionedName:).*|\1       Unofficial Gentoo EasyInstall (KDE)|' \
  -e 's|^(\s*shortVersionedName:).*|\1  Gentoo EasyInstall|' \
  "$B"
grep -q 'Unofficial Gentoo EasyInstall' "$B" || { echo "ERROR: branding not applied"; exit 1; }

# --- live initramfs: generic (not host-only) + dmsquash-live; the same image later boots the installed system ---
# (--no-hostonly must be on the command line: /usr/lib/dracut/dracut.conf.d/01-gentoo.conf forces host-only)
rm -f /etc/dracut.conf.d/00-live.conf /etc/dracut.conf.d/99-live.conf
KVER=$(ls /lib/modules | sort -V | tail -1)
dracut -f --no-hostonly --add dmsquash-live --omit "plymouth" --compress zstd \
  --kver "$KVER" "/boot/initramfs-$KVER.img"
lsinitrd "/boot/initramfs-$KVER.img" > /tmp/lsinitrd.txt
grep -q dmsquash-live-root /tmp/lsinitrd.txt || { echo "ERROR: dmsquash-live missing from initramfs"; exit 1; }

# --- cleanup ---
rm -rf /var/cache/binhost/* /var/cache/distfiles/* /var/cache/binpkgs/* /var/tmp/portage/* /tmp/*
rm -f /etc/machine-id /var/lib/dbus/machine-id
echo "OK: live system configured, kernel $KVER"
