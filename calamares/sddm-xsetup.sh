#!/bin/sh
# SDDM greeter setup (X11): apply the keyboard layout chosen in the installer to the login screen,
# so passwords with non-US characters can be typed. Calamares writes the layout as an X11 config file.
for f in /etc/X11/xorg.conf.d/00-keyboard.conf /usr/share/X11/xorg.conf.d/00-keyboard.conf; do
  [ -s "$f" ] || continue
  layout=$(sed -n 's/.*"XkbLayout"[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n1)
  variant=$(sed -n 's/.*"XkbVariant"[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n1)
  [ -n "$layout" ] && { setxkbmap -layout "$layout" ${variant:+-variant "$variant"}; break; }
done
exec /usr/share/sddm/scripts/Xsetup
