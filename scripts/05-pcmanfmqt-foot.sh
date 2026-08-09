#!/bin/sh
# 05-pcmanfmqt-foot.sh — install pcmanfm-qt (Debian) and foot (from Devuan-Depot).
set -eu

install_pkg() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        sudo apt install -y "$1"
        echo "05: $1 instalado"
    else
        echo "05: $1 ya instalado"
    fi
}

# foot comes from Devuan-Depot, so 01-devuan-depot.sh must have run.
install_pkg pcmanfm-qt
install_pkg foot

echo "05: pcmanfm-qt + foot listos. Revisar el item 'Archiver' en Preferencias de pcmanfm-qt (apunte a xarchiver bien configurado)."