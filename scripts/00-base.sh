#!/bin/sh
# 00-base.sh — base system: upgrade + firmware + build tools + locales + seatd.
# Run as root (sudo not installed yet at this stage).
set -eu

# Idempotency helper: returns 0 (true) if any package in the list is missing.
needs_install() {
    for pkg in "$@"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

PACKAGES="firmware-amd-graphics mesa-vulkan-drivers libgl1-mesa-dri build-essential git curl wget gnupg ca-certificates locales seatd"

if [ "$(id -u)" -ne 0 ]; then
    echo "00: ERROR: este script debe correrse como root (sin sudo). corri: su -c '$0'  o  logearse como root" >&2
    exit 1
fi

# needs_install eats its args word-split; we want split here intentionally.
# shellcheck disable=SC2086
if needs_install $PACKAGES; then
    apt update
    apt full-upgrade -y
    # shellcheck disable=SC2086
    apt install -y $PACKAGES
else
    echo "00: todos los paquetes base ya estan instalados"
fi

# Generate es_AR.UTF-8 locale if not present.
if ! locale -a 2>/dev/null | grep -qx "es_AR.utf8"; then
    if grep -q "^#.*es_AR.UTF-8" /etc/locale.gen 2>/dev/null; then
        sed -i 's/^#\(es_AR.UTF-8.*\)/\1/' /etc/locale.gen
    elif ! grep -q "^es_AR.UTF-8" /etc/locale.gen 2>/dev/null; then
        echo "es_AR.UTF-8 UTF-8" >> /etc/locale.gen
    fi
    locale-gen
    echo "00: locale es_AR.UTF-8 generado"
else
    echo "00: locale es_AR.UTF-8 ya generado"
fi

# Set default locale if not already.
if ! grep -q '^LANG="es_AR.UTF-8"' /etc/default/locale 2>/dev/null; then
    update-locale LANG=es_AR.UTF-8 LANGUAGE=es_AR:es
    echo "00: /etc/default/locale actualizado"
else
    echo "00: /etc/default/locale ya configurado"
fi

echo "00: base lista. Continuar con 01-devuan-depot.sh (todavia como root)."