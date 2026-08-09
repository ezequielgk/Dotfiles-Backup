#!/bin/sh
# 03b-nix-homemanager.sh — install Nix (single-user, no daemon) + enable flakes
# + add channels + bootstrap home-manager with `init` (NO switch — switch is
# manual after the restore copies the real flake).
# Run as the regular user. The Nix installer refuses root, so no sudo here.
set -eu

# Idempotency: skip install entirely if nix is already on PATH and /nix exists.
if command -v nix >/dev/null 2>&1 && [ -d /nix ]; then
    echo "03b: Nix ya instalado, saltando install"
else
    if [ "$(id -u)" -eq 0 ]; then
        echo "03b: ERROR: el installer de Nix single-user rechaza root. correr como usuario normal" >&2
        exit 1
    fi
    echo "03b: instalando Nix single-user (no daemon)..."
    sh "$(curl -L https://nixos.org/nix/install)" --no-confirm
fi

# Make nix visible in this script's process (installer writes /etc/profile.d/nix.sh).
# shellcheck disable=SC1091
if [ -f /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
fi

command -v nix >/dev/null 2>&1 || {
    echo "03b: ERROR: nix no esta en PATH despues del install. Hace falta re-login o sourcear /etc/profile.d/nix.sh" >&2
    exit 1
}

# Enable flakes in the user nix.conf (idempotent).
mkdir -p "${HOME}/.config/nix"
CONF="${HOME}/.config/nix/nix.conf"
if [ ! -f "$CONF" ] || ! grep -q "^experimental-features" "$CONF" 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> "$CONF"
    echo "03b: flakes habilitados en $CONF"
else
    echo "03b: flakes ya habilitados en $CONF"
fi

# Add channels (idempotent: check `nix-channel --list` first).
hm_url="https://github.com/nix-community/home-manager/archive/master.tar.gz"
nx_url="https://channels.nixos.org/nixpkgs-unstable"

if ! nix-channel --list 2>/dev/null | grep -q "^home-manager "; then
    nix-channel --add "$hm_url" home-manager
    echo "03b: canal home-manager agregado"
else
    echo "03b: canal home-manager ya agregado"
fi
if ! nix-channel --list 2>/dev/null | grep -q "^nixpkgs "; then
    nix-channel --add "$nx_url" nixpkgs
    echo "03b: canal nixpkgs agregado"
else
    echo "03b: canal nixpkgs ya agregado"
fi

nix-channel --update

# Bootstrap home-manager with `init` ONLY if no home.nix exists.
# The restore overwrites this scaffold with the real flake.
HM_HOME="${HOME}/.config/home-manager/home.nix"
if [ ! -f "$HM_HOME" ]; then
    nix run home-manager/master -- init
    echo "03b: home-manager init ejecutado (scaffold en $HM_HOME)"
else
    echo "03b: $HM_HOME ya existe, no se hace init (se sobreescribira con el restore)"
fi

cat <<EOF

03b: Nix + home-manager listos. NO se switchio.
Despues del restore (categoria 'home-manager' del backup), correr manualmente:

  nix run home-manager/master -- switch --flake ~/.config/home-manager#$(id -un) --impure

EOF