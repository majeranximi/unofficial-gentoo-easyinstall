#!/bin/bash
# Packs rootfs/ into a hybrid BIOS + UEFI ISO. Run: sudo ./make-iso.sh
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
LABEL=GENTOO_EASYINSTALL
OUT=unofficial-gentoo-easyinstall-kde-$(date +%Y%m%d).iso
W=work/iso
for m in run dev sys proc; do umount -Rl rootfs/$m 2>/dev/null || true; done

rm -rf work && mkdir -p $W/LiveOS $W/boot/grub
KVER=$(ls rootfs/lib/modules | sort -V | tail -1)
cp rootfs/boot/vmlinuz-$KVER $W/boot/vmlinuz
cp rootfs/boot/initramfs-$KVER.img $W/boot/initramfs.img

mksquashfs rootfs $W/LiveOS/squashfs.img -comp zstd -Xcompression-level 19 -b 1M -noappend -no-progress \
  -e proc/* sys/* dev/* run/* tmp/* var/tmp/* root/calamares root/setup-live.sh root/iso-pkgs

cat > $W/boot/grub/grub.cfg <<EOF
set timeout=5
set default=0
insmod all_video
insmod part_msdos
insmod part_gpt
insmod ext2
insmod fat
# The installer leaves /boot/gentoo-installed (BIOS: on the root partition; UEFI: /boot is the ESP, so at its root).
# If found, the first entry boots the installed system, so the ISO does not have to be ejected after installing.
if search --no-floppy --file --set=inst /boot/gentoo-installed; then
  set cfg=/boot/grub/grub.cfg
elif search --no-floppy --file --set=inst /gentoo-installed; then
  set cfg=/grub/grub.cfg
fi
export inst cfg
if [ -n "\$inst" ]; then
  menuentry "Boot installed Gentoo (from disk)" {
    set root=\$inst
    configfile \$cfg
  }
fi
menuentry "Unofficial Gentoo EasyInstall (KDE Live)" {
  linux /boot/vmlinuz root=live:CDLABEL=$LABEL rd.live.image quiet splash
  initrd /boot/initramfs.img
}
menuentry "Unofficial Gentoo EasyInstall (safe graphics, nomodeset)" {
  linux /boot/vmlinuz root=live:CDLABEL=$LABEL rd.live.image nomodeset
  initrd /boot/initramfs.img
}
menuentry "Unofficial Gentoo EasyInstall (copy to RAM)" {
  linux /boot/vmlinuz root=live:CDLABEL=$LABEL rd.live.image rd.live.ram=1 quiet
  initrd /boot/initramfs.img
}
EOF

grub-mkrescue -o "$OUT" $W -- -volid $LABEL
sha256sum "$OUT" > "$OUT.sha256"
chown "${SUDO_UID:-0}:${SUDO_GID:-0}" "$OUT" "$OUT.sha256"
ls -lh "$OUT"
