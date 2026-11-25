#!/bin/bash
# Runs a command inside the Gentoo rootfs: sudo ./chroot.sh 'emerge -av foo'
set -e
R="$(dirname "$(readlink -f "$0")")/rootfs"
mountpoint -q "$R/proc" || {
  mount -t proc proc "$R/proc"
  mount --rbind /sys "$R/sys"; mount --make-rslave "$R/sys"
  mount --rbind /dev "$R/dev"; mount --make-rslave "$R/dev"
  mount --bind /run "$R/run"; mount --make-slave "$R/run"
}
cp -L /etc/resolv.conf "$R/etc/resolv.conf"
chroot "$R" /bin/bash -lc "$*"
