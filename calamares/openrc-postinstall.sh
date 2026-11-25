#!/bin/sh
# Run by Calamares (shellprocess) inside the installed system.
# Calamares writes systemd-style locale/keyboard files; OpenRC and Plasma read different ones.
# Optional $1 = root prefix (only for testing outside a chroot).
set -eu
R="${1:-}"

# Language: /etc/locale.conf -> /etc/env.d/02locale (OpenRC ignores locale.conf)
if [ -s "$R/etc/locale.conf" ]; then
  cp "$R/etc/locale.conf" "$R/etc/env.d/02locale"
fi

# Console keymap: /etc/vconsole.conf (KEYMAP=xx) -> /etc/conf.d/keymaps
if [ -s "$R/etc/vconsole.conf" ]; then
  km=$(sed -n 's/^KEYMAP=["]*\([^"]*\)["]*$/\1/p' "$R/etc/vconsole.conf" | head -n1)
  [ -n "$km" ] && echo "keymap=\"$km\"" > "$R/etc/conf.d/keymaps"
fi

# Desktop keyboard: X11 config written by Calamares -> Plasma kxkbrc for every user + new users
layout=""; variant=""
for f in "$R/etc/X11/xorg.conf.d/00-keyboard.conf" "$R/usr/share/X11/xorg.conf.d/00-keyboard.conf"; do
  [ -s "$f" ] || continue
  layout=$(sed -n 's/.*"XkbLayout"[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n1)
  variant=$(sed -n 's/.*"XkbVariant"[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n1)
  [ -n "$layout" ] && break
done
if [ -n "$layout" ]; then
  for home in "$R/etc/skel" "$R"/home/*; do
    [ -d "$home" ] || continue
    mkdir -p "$home/.config"
    printf '[Layout]\nLayoutList=%s\nVariantList=%s\nUse=true\n' "$layout" "$variant" > "$home/.config/kxkbrc"
    [ "$home" = "$R/etc/skel" ] || chown -R --reference="$home" "$home/.config"
  done
fi

[ -z "$R" ] && env-update >/dev/null 2>&1 || true
