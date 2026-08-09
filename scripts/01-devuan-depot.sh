#!/bin/sh
# 01-devuan-depot.sh — add the user's personal APT repo (Devuan-Depot).
# Run as root (sudo not installed yet at this stage).
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "01: ERROR: este script debe correrse como root" >&2
    exit 1
fi

KEYRING="/usr/share/keyrings/devuan-depot.gpg"
LIST="/etc/apt/sources.list.d/devuan-depot.list"
URL="https://ezequielgk.github.io/devuan-depot"

# Import GPG key (idempotent on file existence).
if [ ! -f "$KEYRING" ]; then
    curl -fsSL "$URL/public.asc" | gpg --dearmor -o "$KEYRING"
    chmod a+r "$KEYRING"
    echo "01: keyring importado en $KEYRING"
else
    echo "01: keyring ya existe"
fi

# Add sources.list (idempotent: write only if line not present).
LINE="deb [arch=amd64 signed-by=$KEYRING] $URL trixie main"
if [ ! -f "$LIST" ] || ! grep -qF "$URL" "$LIST" 2>/dev/null; then
    printf '%s\n' "$LINE" > "$LIST"
    chmod a+r "$LIST"
    echo "01: sources.list creado"
else
    echo "01: sources.list ya configurado"
fi

apt update
echo "01: Devuan-Depot listo. Continuar con 02-sudo-doas.sh (como usuario)."