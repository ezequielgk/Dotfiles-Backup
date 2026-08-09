#!/bin/sh
# restore-from-backup.sh — copy each backup category back to its original
# location, but ONLY after the corresponding install script has run. Prompts
# per category; refuses to overwrite existing files without explicit consent.
#
# Usage: restore-from-backup.sh [BACKUP_DIR]
#   BACKUP_DIR defaults to ~/devuan-migration/backup
set -eu

BACKUP="${1:-${HOME}/devuan-migration/backup}"
MANIFEST="$BACKUP/MANIFEST.md"

if [ ! -f "$MANIFEST" ]; then
    echo "restore: ERROR: MANIFEST.md no encontrado en $BACKUP" >&2
    exit 1
fi

USER_NAME="$(id -un)"

# Prompt y/n/a. Default 'n'.
confirm() {
    prompt="$1"
    printf '%s [s/n/a]: ' "$prompt"
    read -r ans
    case "$ans" in
        s|S) return 0 ;;
        n|N|"") return 1 ;;
        a|A)
            echo "restore: abortado por el usuario"
            exit 1
            ;;
        *)
            echo "respuesta invalida, interpretando como 'n'"
            return 1
            ;;
    esac
}

# Ask before overwriting an existing dest path.
confirm_overwrite() {
    dest="$1"
    if [ -e "$dest" ]; then
        printf '  WARNING: %s ya existe. Sobreescribir? [s/N]: ' "$dest"
        read -r ow
        case "$ow" in
            s|S) return 0 ;;
            *) return 1 ;;
        esac
    fi
    return 0
}

pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }

# Generic copy helper (no sudo).
#   copy_user <backup_src> <dest_dir>
copy_user() {
    src="$1"
    dest_dir="$2"
    [ -e "$src" ] || { echo "   -- saltando (no existe en backup): $src"; return 0; }

    base=$(basename "$src")
    dest="$dest_dir/$base"
    if ! confirm "  Copiar $src -> $dest ?"; then
        echo "   -- saltado por el usuario"
        return 0
    fi
    if ! confirm_overwrite "$dest"; then
        echo "   -- no se sobreescribio $dest"
        return 0
    fi
    mkdir -p "$dest_dir"
    cp -a "$src" "$dest_dir/"
    echo "   OK: $src -> $dest"
}

# Sudo copy for root-owned /etc paths (preserves literal ownership/mode).
#   copy_root <backup_src> <dest_dir>
copy_root() {
    src="$1"
    dest_dir="$2"
    [ -e "$src" ] || { echo "   -- saltando (no existe en backup): $src"; return 0; }

    base=$(basename "$src")
    dest="$dest_dir/$base"
    if ! confirm "  Copiar $src -> $dest ? (sudo)"; then
        echo "   -- saltado por el usuario"
        return 0
    fi
    if ! sudo test -e "$dest"; then
        :
    else
        printf '  WARNING: %s ya existe. Sobreescribir? [s/N]: ' "$dest"
        read -r ow
        case "$ow" in
            s|S) ;;
            *) echo "   -- no se sobreescribio $dest"; return 0 ;;
        esac
    fi
    sudo mkdir -p "$dest_dir"
    sudo cp -a "$src" "$dest_dir/"
    echo "   OK: $src -> $dest"
}

restored=""

# --- wm (requires mangowc + fish) ---
echo
echo ">> Categoria: wm  (requiere: 07 mangowc, 03 fish)"
if pkg_installed mangowc && pkg_installed fish; then
    copy_user "$BACKUP/wm/sway"        "${HOME}/.config"
    copy_user "$BACKUP/wm/mango"       "${HOME}/.config"
    restored="$restored wm"
else
    echo "   -- saltando wm: falta mangowc y/o fish"
fi

# --- terminal ---
echo
echo ">> Categoria: terminal  (sin dependencias)"
copy_user "$BACKUP/terminal/foot" "${HOME}/.config"
restored="$restored terminal"

# --- shell (requires fish) ---
echo
echo ">> Categoria: shell  (requiere: 03 fish)"
if pkg_installed fish; then
    copy_user "$BACKUP/shell/fish" "${HOME}/.config"
    restored="$restored shell"
else
    echo "   -- saltando shell: falta fish"
fi

# --- noctalia (requires noctalia) ---
echo
echo ">> Categoria: noctalia  (requiere: 07 noctalia)"
if pkg_installed noctalia; then
    copy_user "$BACKUP/noctalia/config/noctalia" "${HOME}/.config"
    copy_user "$BACKUP/noctalia/state/noctalia"  "${HOME}/.local/state"
    restored="$restored noctalia"
else
    echo "   -- saltando noctalia: falta el paquete noctalia"
fi

# --- portal ---
echo
echo ">> Categoria: portal  (sin dependencias)"
copy_user "$BACKUP/portal/xdg-desktop-portal" "${HOME}/.config"
restored="$restored portal"

# --- home-manager (requires nix + 03b init) ---
echo
echo ">> Categoria: home-manager  (requiere: 03b nix + home-manager init)"
if command -v nix >/dev/null 2>&1; then
    # The init in 03b created a scaffold home.nix; this overwrites with the real flake.
    if [ -e "${HOME}/.config/home-manager" ] && ! confirm "  ${HOME}/.config/home-manager ya existe (posible scaffold del 03b). Sobreescribir todo el dir ?"; then
        echo "   -- saltando home-manager (no se sobreescribio)"
    else
        rm -rf "${HOME}/.config/home-manager"
        copy_user "$BACKUP/home-manager/home-manager" "${HOME}/.config"
        restored="$restored home-manager"
    fi
else
    echo "   -- saltando home-manager: nix no instalado (corriste 03b?)"
fi

# --- appearance ---
echo
echo ">> Categoria: appearance  (sin dependencias)"
copy_user "$BACKUP/appearance/themes" "${HOME}/.local/share"
copy_user "$BACKUP/appearance/icons"  "${HOME}/.local/share"
copy_user "$BACKUP/appearance/fonts"  "${HOME}/.local/share"
restored="$restored appearance"

# --- emptty (requires emptty) ---
echo
echo ">> Categoria: emptty  (requiere: 06 emptty; sudo para /etc)"
if pkg_installed emptty; then
    copy_root "$BACKUP/emptty/etc/emptty/conf-tty7" "/etc/emptty"
    copy_root "$BACKUP/emptty/etc/emptty/motd"     "/etc/emptty"
    # Force 0640 on conf-tty7 regardless of the mode the backup file has.
    # Git stores only 100644 or 100755 in its index — it normalizes 0640 to 0644,
    # so a fresh clone ends up at 0644. The original is 0640 root:root.
    sudo chmod 0640 /etc/emptty/conf-tty7 2>/dev/null || true
    restored="$restored emptty"
    echo "   NOTA: sv restart emptty para que tome la config nueva: sudo sv restart emptty"
else
    echo "   -- saltando emptty: falta el paquete emptty"
fi

# --- pam (requires libpam-gnome-keyring + libpam-elogind) ---
echo
echo ">> Categoria: pam  (requiere: 08 libpam-gnome-keyring, 08b libpam-elogind; sudo)"
if pkg_installed libpam-gnome-keyring; then
    copy_root "$BACKUP/pam/etc/pam.d/emptty" "/etc/pam.d"
    restored="$restored pam"
    echo "   NOTA: reiniciar emptty (sv restart emptty) y re-login para que tome el PAM hook"
else
    echo "   -- saltando pam: falta libpam-gnome-keyring (corriste 08?)"
fi

# Final report.
cat <<EOF

=== Restore terminado ===
Categorias restauradas:$restored

Pasos manuales pendientes:
EOF

if echo "$restored" | grep -q " home-manager"; then
    cat <<EOF
  1. Activar tu flake real de home-manager:
       nix run home-manager/master -- switch --flake ~/.config/home-manager#${USER_NAME} --impure
EOF
else
    echo "  1. (home-manager no se restauro — verificar paso 03b y re-correr este restore)"
fi

if echo "$restored" | grep -q " emptty"; then
    echo "  2. Reiniciar emptty para que tome /etc/emptty/conf-tty7:  sudo sv restart emptty"
fi

if echo "$restored" | grep -q " pam"; then
    echo "  3. Re-login para que el hook PAM de gnome-keyring tome efecto"
fi

echo
echo "Done."