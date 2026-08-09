#!/bin/sh
# 03-fish-strawberry.sh — install fish + strawberry, set fish as login shell.
set -eu

USER_NAME="$(id -un)"

install_pkg() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        sudo apt install -y "$1"
        echo "03: $1 instalado"
    else
        echo "03: $1 ya instalado"
    fi
}

install_pkg fish
install_pkg strawberry

# Change login shell to fish idempotently.
current_shell=$(getent passwd "$USER_NAME" | cut -d: -f7)
if [ "$current_shell" != "/usr/bin/fish" ]; then
    sudo chsh -s /usr/bin/fish "$USER_NAME"
    echo "03: login shell cambiado a fish (tomara efecto en el proximo login)"
else
    echo "03: login shell ya es fish"
fi

echo "03: fish + strawberry listos."