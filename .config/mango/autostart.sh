#!/bin/bash
# ~/.config/mango/autostart.sh

# Cargar variables de entorno del usuario (incluyendo Nix)
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# Asegurar que XDG_DATA_DIRS incluya Nix para que aparezcan las apps en el launcher
export XDG_DATA_DIRS="$HOME/.nix-profile/share:$HOME/.local/share/applications:/usr/share:$XDG_DATA_DIRS"

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
gsettings set $gnome_schema font-name "Maple Mono"
gsettings set $gnome_schema icon-theme "Noctalia-Colloid-Dark"

#gsettings set $gnome_schema font-name "CozzeteVector"

# 4. Programas
killall -q noctalia
noctalia &
