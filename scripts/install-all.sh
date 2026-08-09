#!/usr/bin/env bash
# install-all.sh — orchestrator. Runs the install scripts 02..10 in order,
# pausing between each for the user to confirm. Stops on first failure.
# Logs everything to ~/devuan-migration/install.log with timestamps.
# After all scripts succeed, runs restore-from-backup.sh automatically.
#
# Uses bash for `pipefail` (POSIX sh has no pipefail). The individual scripts
# are POSIX sh; only this orchestrator is bash.
#
# Pre-condition: 00-base.sh and 01-devuan-depot.sh have already been run AS
# ROOT by the user. This script starts at 02 (sudo/doas must already exist).
set -euo pipefail

SCRIPTS_DIR="${HOME}/devuan-migration/scripts"
BACKUP_DIR="${HOME}/devuan-migration/backup"
LOG="${HOME}/devuan-migration/install.log"

# Order: 00 and 01 ran as root. 04 removed (no OpenTabletDriver). 09 removed
# (no Limine — sticking with grub). 03b before 03 so nix is ready early.
# 04b installs audio between 03 and 05 (after fish, before pcmanfm/foot).
ORDER=(
    02-sudo-doas.sh
    03b-nix-homemanager.sh
    03-fish-strawberry.sh
    04b-audio.sh
    05-pcmanfmqt-foot.sh
    05b-qt6ct.sh
    06-emptty.sh
    07-mango-noctalia-dotfiles.sh
    08-keyring.sh
    08b-polkit.sh
    10-zram-swap.sh
)

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '[%s] %s\n' "$(timestamp)" "$*" | tee -a "$LOG" >&2; }

# Sanity: make sure 00 and 01 actually ran.
if ! dpkg -s sudo >/dev/null 2>&1; then
    echo "install-all: ERROR: sudo no esta instalado. ¿Corriste 00-base.sh y 01-devuan-depot.sh como root?" >&2
    exit 1
fi
if [ ! -f /usr/share/keyrings/devuan-depot.gpg ] && [ ! -f /etc/apt/sources.list.d/devuan-depot.list ]; then
    echo "install-all: WARNING: Devuan-Depot no configurado. ¿Corriste 01-devuan-depot.sh? foot y mangowc pueden fallar." >&2
    read -r -p "Continuar de todos modos? [s/N]: " ans
    case "$ans" in s|S) ;; *) exit 1 ;; esac
fi

log "=== INICIO install-all.sh ==="
log "Scripts a correr (en orden): ${ORDER[*]}"

for script in "${ORDER[@]}"; do
    path="$SCRIPTS_DIR/$script"
    log ">>> Proximo script: $script"

    while true; do
        printf '\n=== %s ===\n' "$script"
        printf '[s] correr / [r] reintentar / [a] abortar todo (default: s): '
        read -r action
        case "$action" in
            r|R) log "Reintentando %s (solicitud del usuario)" "$script"; continue ;;
            a|A) log "ABORTADO antes de %s" "$script"; exit 1 ;;
            s|S|"") break ;;
            *) echo "respuesta invalida, interpretando como 's'"; break ;;
        esac
    done

    if [ ! -x "$path" ]; then
        log "ERROR: %s no existe o no es ejecutable" "$path"
        exit 1
    fi

    # Run and capture output, propagate failure (pipefail).
    tmp=$(mktemp)
    if ! bash "$path" >"$tmp" 2>&1; then
        tee -a "$LOG" <"$tmp"
        rm -f "$tmp"
        log "FALLO: %s devolvio error. Deteniendo." "$script"
        exit 1
    fi
    tee -a "$LOG" <"$tmp"
    rm -f "$tmp"
    log "OK: %s termino bien" "$script"
done

log "=== Todos los scripts terminaron OK ==="

# Auto-launch restore-from-backup.sh.
RESTORE="$SCRIPTS_DIR/restore-from-backup.sh"
if [ -x "$RESTORE" ]; then
    log "Lanzando restore-from-backup.sh $BACKUP_DIR ..."
    printf '\n=== Restore desde backup ===\n'
    if bash "$RESTORE" "$BACKUP_DIR" 2>&1 | tee -a "$LOG"; then
        log "Restore termino."
    else
        log "Restore devolvio error, revisar log"
    fi
else
    log "restore-from-backup.sh no encontrado en $SCRIPTS_DIR — saltando restore automatico"
fi

log "=== DONE ==="

cat <<EOF

install-all.sh completo.
Pasos manuales restantes (ver output del restore arriba):

  1. Activar tu flake de home-manager:
       nix run home-manager/master -- switch --flake ~/.config/home-manager#$(id -un) --impure

  2. Reiniciar emptty:
       sudo sv restart emptty

  3. Re-logear para que PAM hook de gnome-keyring tome efecto.

  4. Verificar servicios:
       sv status /etc/runit/runsvdir/default/*

  5. Verificar swaps:
       swapon --show

EOF