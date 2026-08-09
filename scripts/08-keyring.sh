#!/bin/sh
# 08-keyring.sh — install gnome-keyring + libpam-gnome-keyring for auto-unlock.
# The PAM hook (auth/session pam_gnome_keyring.so in /etc/pam.d/emptty) is
# restored separately via backup category 'pam'. Not critical: without it the
# system still works, the keyring just asks for its password the first time.
set -eu

install_pkg() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        sudo apt install -y "$1"
        echo "08: $1 instalado"
    else
        echo "08: $1 ya instalado"
    fi
}

install_pkg gnome-keyring
install_pkg libpam-gnome-keyring

echo "08: gnome-keyring listo. Restaurar /etc/pam.d/emptty desde la categoria 'pam' del backup para auto-unlock."