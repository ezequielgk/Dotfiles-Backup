#!/bin/bash
# ~/.config/mango/autostart.sh

echo "$(date): $(free -h | grep Mem)" >> ~/ram_history.log

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

export XDG_DATA_DIRS="$HOME/.local/share:/usr/share:$XDG_DATA_DIRS"

# 1. Portales y Secretos

export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt6ct
dbus-update-activation-environment --all

# /usr/libexec/xdg-desktop-portal-wlr &  # D-Bus lo activa solo bajo demanda
# /usr/libexec/xdg-desktop-portal &  # idem


# 1.1 Portapapeles (Clipboard)

wl-clip-persist --clipboard regular --reconnect-tries 0 2>/dev/null &
wl-paste --type text --watch cliphist store &


# 2. Audio (Pipewire)

killall -q pipewire wireplumber pipewire-pulse
pipewire &
wireplumber &
pipewire-pulse &

# 3. GTK Theme
gnome_schema="org.gnome.desktop.interface"

# (Original)
gsettings set $gnome_schema gtk-theme "adw-gtk3-dark"
gsettings set $gnome_schema cursor-theme "Adwaita"
gsettings set $gnome_schema font-name "Terminess Font"
gsettings set $gnome_schema icon-theme "Noctalia-Colloid"
#gsettings set $gnome_schema icon-theme "Noctalia-Papirus"
#gsettings set $gnome_schema font-name "CozzeteVector"

# 4. Programas
killall -q noctalia

#swayidle -w \
   # timeout 600 'noctalia msg session lock' \
   # timeout 700 'noctalia msg dpms-off' \
   # resume 'noctalia msg dpms-on' \
   # timeout 900 'loginctl suspend' &

noctalia &
