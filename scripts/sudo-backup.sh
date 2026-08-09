#!/bin/sh
# Backup the 2 root-owned categories (emptty, pam) with sudo cp -a to preserve
# literal ownership/mode. Run as root: `sudo bash sudo-backup.sh`.
# Idempotent: skips files already present at the destination.
set -eu

# Use absolute path: sudo resets $HOME to /root, which would break the destination.
BACKUP="/home/ezequiel/devuan-migration/backup"

# Resolve MOTD path from the emptty conf. The conf may set MOTD via a
# directive like `MOTD_PATH=...`, `MOTD=...`, or just reference the file.
# Fallback to /etc/emptty/motd if the conf has no explicit directive.
resolve_motd() {
    conf="$1"
    motd=$(grep -iE '^[[:space:]]*(MOTD_PATH|MOTD)[[:space:]]*=' "$conf" 2>/dev/null \
        | head -1 \
        | sed -E 's/^[^=]+=[[:space:]]*//; s/#.*$//; s/[[:space:]]*$//')
    if [ -n "$motd" ] && [ -e "$motd" ]; then
        printf '%s\n' "$motd"
    elif [ -e /etc/emptty/motd ]; then
        printf '/etc/emptty/motd\n'
    else
        printf '\n'
    fi
}

copy_root_file() {
    src="$1"
    dest_dir="$2"
    [ -e "$src" ] || { printf '   -- saltando (no existe): %s\n' "$src"; return 0; }
    base=$(basename "$src")
    target="$dest_dir/$base"
    if [ -e "$target" ]; then
        printf '   == ya respaldado: %s\n' "$src"
        return 0
    fi
    mkdir -p "$dest_dir"
    cp -a "$src" "$dest_dir/"
    printf '   OK copiado: %s -> %s\n' "$src" "$target"
}

printf '\n>> Categoria: emptty (sudo)\n'
conf=/etc/emptty/conf-tty7
copy_root_file "$conf" "$BACKUP/emptty/etc/emptty"
motd=$(resolve_motd "$conf")
if [ -n "$motd" ]; then
    printf '   MOTD referenciado por conf: %s\n' "$motd"
    copy_root_file "$motd" "$BACKUP/emptty/etc/emptty"
else
    printf '   (conf no referencia MOTD y /etc/emptty/motd no existe)\n'
fi

printf '\n>> Categoria: pam (sudo)\n'
copy_root_file /etc/pam.d/emptty "$BACKUP/pam/etc/pam.d"

printf '\nBackup sudo listo en %s/emptty y %s/pam.\n' "$BACKUP" "$BACKUP"
printf 'Ahora correr (como usuario, no root):\n'
printf '  bash %s/commit-sudo.sh\n' "/home/ezequiel/devuan-migration/scripts"