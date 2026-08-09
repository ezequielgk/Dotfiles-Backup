#!/bin/sh
# 07-mango-noctalia-dotfiles.sh — install mangowc (Devuan-Depot) and noctalia
# (its own APT repo). Dotfiles are NOT cloned here; restore-from-backup.sh
# copies them back from backup categories 'wm' and 'noctalia'.
set -eu

# mangowc from Devuan-Depot (01-devuan-depot.sh must have run).
if ! dpkg -s mangowc >/dev/null 2>&1; then
    sudo apt install -y mangowc
    echo "07: mangowc instalado"
else
    echo "07: mangowc ya instalado"
fi

# Noctalia keyring package.
KEYRING_DEB="/tmp/nickh-archive-keyring.deb"
if ! dpkg -s nickh-archive-keyring >/dev/null 2>&1; then
    wget -q -O "$KEYRING_DEB" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
    sudo dpkg -i "$KEYRING_DEB"
    rm -f "$KEYRING_DEB"
    echo "07: noctalia keyring instalado"
else
    echo "07: noctalia keyring ya instalado"
fi

# Noctalia sources.list.
NOCTALIA_SOURCES="/etc/apt/sources.list.d/noctalia-trixie.sources"
if [ ! -f "$NOCTALIA_SOURCES" ]; then
    sudo wget -q -O "$NOCTALIA_SOURCES" https://pkg.noctalia.dev/deb/noctalia-trixie.sources
    sudo apt update
    echo "07: noctalia sources agregadas"
else
    echo "07: noctalia sources ya configuradas"
fi

# noctalia package.
if ! dpkg -s noctalia >/dev/null 2>&1; then
    sudo apt install -y noctalia
    echo "07: noctalia instalado"
else
    echo "07: noctalia ya instalado"
fi

cat <<EOF

07: mangowc + noctalia instalados.
Los dotfiles (~/.config/mango, ~/.config/noctalia, ~/.local/state/noctalia,
~/.config/sway) se restauran con restore-from-backup.sh desde las categorias
'wm' y 'noctalia' del backup.

EOF