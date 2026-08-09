#!/bin/sh
# 05b-qt6ct.sh — install qt6ct. The env vars (QT_QPA_PLATFORM, QT_QPA_PLATFORMTHEME,
# QT_WAYLAND_DISABLE_WINDOWDECORATION, dbus-update-activation-environment --all)
# already live in ~/.config/mango/autostart.sh, restored via backup category
# 'wm'. Nothing to wire here — just the package.
set -eu

if ! dpkg -s qt6ct >/dev/null 2>&1; then
    sudo apt install -y qt6ct
    echo "05b: qt6ct instalado"
else
    echo "05b: qt6ct ya instalado"
fi

echo "05b: configurar tema/iconos/fuentes con 'qt6ct' en terminal (despues del restore del autostart.sh)."