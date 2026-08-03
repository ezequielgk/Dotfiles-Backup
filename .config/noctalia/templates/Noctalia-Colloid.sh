#!/usr/bin/env bash
PRI="{{colors.primary.default.hex}}"
C1="${PRI:1}"
T_DIR="$HOME/.icons/Noctalia-Colloid-Dark"

# Hard Reset para limpiar colores previos antes de aplicar el nuevo
git -C "$T_DIR" reset --hard -q original
git -C "$T_DIR" clean -fd -q

# Reemplazo de color maestro (Carpetas, degradados y apps)
find "$T_DIR" -name "*.svg" -type f -print0 | xargs -0 sed -i -E \
    -e "s/#60c0f0/#${C1}/gI" \
    -e "s/#5294e2/#${C1}/gI" \
    -e "s/fill:#[0-9a-fA-F]{6}/fill:#${C1}/gI" \
    -e "s/stop-color:#[0-9a-fA-F]{6}/stop-color:#${C1}/gI" \
    -e "s/style=\"fill:#[0-9a-fA-F]{6}/style=\"fill:#${C1}/gI" \
    -e "s/currentColor/#${C1}/gI"

gtk-update-icon-cache -f -t "$T_DIR" 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme "hicolor"
sleep 0.2
gsettings set org.gnome.desktop.interface icon-theme "Noctalia-Colloid-Dark"
