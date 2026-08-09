#!/bin/sh
# 02-sudo-doas.sh — install sudo + doas, configure /etc/doas.conf, add user to sudo group.
# Run as the regular user (uses sudo). Requires 00 and 01 to have run as root.
set -eu

USER_NAME="$(id -un)"
DOAS_CONF="/etc/doas.conf"

install_pkg() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        sudo apt install -y "$1"
        echo "02: $1 instalado"
    else
        echo "02: $1 ya instalado"
    fi
}

install_pkg sudo
install_pkg doas

# Add user to sudo group idempotently.
if ! id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "sudo"; then
    sudo usermod -aG sudo "$USER_NAME"
    echo "02: $USER_NAME agregado al grupo sudo (requiere re-login para que tome)"
else
    echo "02: $USER_NAME ya esta en el grupo sudo"
fi

# Write /etc/doas.conf idempotently with the exact permit line.
EXPECTED="permit persist $USER_NAME as root"
if [ ! -f "$DOAS_CONF" ] || ! sudo grep -qF "permit persist $USER_NAME" "$DOAS_CONF" 2>/dev/null; then
    printf '%s\n' "$EXPECTED" | sudo tee "$DOAS_CONF" >/dev/null
    sudo chown root:root "$DOAS_CONF"
    sudo chmod 0400 "$DOAS_CONF"
    echo "02: /etc/doas.conf escrito (modo 0400)"
else
    echo "02: /etc/doas.conf ya configurado"
fi

echo "02: sudo + doas listos. Continuar con 03b-nix-homemanager.sh."