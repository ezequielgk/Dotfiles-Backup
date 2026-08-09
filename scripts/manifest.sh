#!/bin/sh
# Generate MANIFEST.md for the backup, listing categories, source -> dest, and
# per-category sizes. Run as ezequiel (no sudo needed for sizes).
#
# shellcheck disable=SC2016,SC2129
# SC2016: printf backticks in single-quoted format strings are literal (printf
#         does not expand shell backticks; shellcheck can't tell).
# SC2129: multiple printf-to-same-file reads cleaner as one redirect block,
#         but the per-line form is more readable for the table iteration.
set -eu

BACKUP="/home/ezequiel/devuan-migration/backup"
MANIFEST="$BACKUP/MANIFEST.md"

# Helper: print a category row in markdown.
emit_category() {
    name="$1"
    printf '\n## %s\n\n' "$name"
}

emit_path() {
    src="$1"
    dest="$2"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            nfiles=$(find "$src" -type f 2>/dev/null | wc -l | tr -d ' ')
            nbytes=$(du -sb "$src" 2>/dev/null | awk '{print $1}')
        else
            nfiles=1
            nbytes=$(du -sb "$src" 2>/dev/null | awk '{print $1}')
        fi
        [ -z "$nbytes" ] && nbytes=0
        printf '| %s | %s | %d archivos | %d B |\n' "$src" "$dest" "$nfiles" "$nbytes"
    else
        printf '| %s | (saltado) | -- | -- | no encontrado |\n' "$src"
    fi
}

{
    printf '# MANIFEST del backup Devuan migration\n\n'
    printf '**Fecha:** %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '**Backup dir:** `%s`\n\n' "$BACKUP"
    printf '## Resumen por categoria\n\n'
    printf '| Categoria | Origen | Destino | Archivos | Tamano |\n'
    printf '|---|---|---|---|---|\n'
} > "$MANIFEST"

# Emit each category. For root-owned categories, we can read sizes only if
# we can traverse the dir; sizes shown as informative only.

{
    printf '| wm | %s/.config/sway | wm/sway | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/sway" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/sway" 2>/dev/null | awk '{print $1}')"
    printf '| wm | %s/.config/mango | wm/mango | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/mango" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/mango" 2>/dev/null | awk '{print $1}')"
} >> "$MANIFEST"

{
    printf '| terminal | %s/.config/foot | terminal/foot | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/foot" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/foot" 2>/dev/null | awk '{print $1}')"
} >> "$MANIFEST"

{
    printf '| shell | %s/.config/fish | shell/fish | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/fish" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/fish" 2>/dev/null | awk '{print $1}')"
} >> "$MANIFEST"

{
    printf '| noctalia | %s/.config/noctalia | noctalia/config/noctalia | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/noctalia" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/noctalia" 2>/dev/null | awk '{print $1}')"
    printf '| noctalia | %s/.local/state/noctalia | noctalia/state/noctalia | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.local/state/noctalia" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.local/state/noctalia" 2>/dev/null | awk '{print $1}')"
} >> "$MANIFEST"

{
    printf '| portal | %s/.config/xdg-desktop-portal | portal/xdg-desktop-portal | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/xdg-desktop-portal" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/xdg-desktop-portal" 2>/dev/null | awk '{print $1}')"
    printf '| portal | /etc/xdg-desktop-portal | (saltado) | -- | -- | no existe |\n'
} >> "$MANIFEST"

{
    printf '| home-manager | %s/.config/home-manager | home-manager/home-manager | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.config/home-manager" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.config/home-manager" 2>/dev/null | awk '{print $1}')"
} >> "$MANIFEST"

{
    printf '| appearance | %s/.local/share/themes | appearance/themes | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.local/share/themes" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.local/share/themes" 2>/dev/null | awk '{print $1}')"
    printf '| appearance | %s/.local/share/icons | appearance/icons | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.local/share/icons" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.local/share/icons" 2>/dev/null | awk '{print $1}')"
    printf '| appearance | %s/.local/share/fonts | appearance/fonts | %d archivos | %d B |\n' \
        "$HOME" "$(find "$HOME/.local/share/fonts" -type f 2>/dev/null | wc -l | tr -d ' ')" \
        "$(du -sb "$HOME/.local/share/fonts" 2>/dev/null | awk '{print $1}')"
} >> "$MANIFEST"

# emptty: root-owned, can stat the dir but not the files (conf-tty7 is 640).
# Use the known sizes from precheck (146 B + 537 B). Note literal mode preserved.
{
    printf '| emptty | /etc/emptty/conf-tty7 | emptty/etc/emptty/conf-tty7 | 1 archivo | 146 B (sudo, literal root:root 640) |\n'
    printf '| emptty | /etc/emptty/motd | emptty/etc/emptty/motd | 1 archivo | 537 B (sudo, literal root:root 644) |\n'
} >> "$MANIFEST"

# pam: /etc/pam.d/emptty is 644, readable.
{
    printf '| pam | /etc/pam.d/emptty | pam/etc/pam.d/emptty | 1 archivo | 1999 B (sudo, literal root:root 644) |\n'
} >> "$MANIFEST"

# Total size.
{
    printf '\n## Total\n\n'
    printf '| Categoria | Tamano total |\n'
    printf '|---|---|\n'
    printf '| wm | %d B |\n' "$(du -sb "$HOME/.config/sway" "$HOME/.config/mango" 2>/dev/null | awk '{s+=$1} END{print s}')"
    printf '| terminal | %d B |\n' "$(du -sb "$HOME/.config/foot" 2>/dev/null | awk '{print $1}')"
    printf '| shell | %d B |\n' "$(du -sb "$HOME/.config/fish" 2>/dev/null | awk '{print $1}')"
    printf '| noctalia | %d B |\n' "$(du -sb "$HOME/.config/noctalia" "$HOME/.local/state/noctalia" 2>/dev/null | awk '{s+=$1} END{print s}')"
    printf '| portal | %d B |\n' "$(du -sb "$HOME/.config/xdg-desktop-portal" 2>/dev/null | awk '{print $1}')"
    printf '| home-manager | %d B |\n' "$(du -sb "$HOME/.config/home-manager" 2>/dev/null | awk '{print $1}')"
    printf '| appearance | %d B |\n' "$(du -sb "$HOME/.local/share/themes" "$HOME/.local/share/icons" "$HOME/.local/share/fonts" 2>/dev/null | awk '{s+=$1} END{print s}')"
    printf '| emptty | 683 B (literal) |\n'
    printf '| pam | 1999 B (literal) |\n'
} >> "$MANIFEST"

# Notes section.
{
    printf '\n## Notas\n\n'
    printf -- '- `/etc/xdg-desktop-portal` no existe en el sistema actual; se saltea con nota (no es error).\n'
    printf -- '- Las categorias `emptty` y `pam` se respaldaron con `sudo cp -a` para preservar ownership literal (root:root, modo 640/644).\n'
    printf -- '- Se detectaron repos git embebidos en `noctalia/state/noctalia/plugins/sources/{community,official}/repo`. Los archivos estan copiados completos en el backup (con sus `.git`), pero git los trackea como gitlinks. Para usar el backup, no afecta. Si se clona el backup repo, esos dirs no aparecen via clone (necesitan tar).\n'
    printf -- '- La categoria `appearance` pesa ~756 MB casi todos en `fonts/` (753 MB / 173 archivos TTF).\n'
    printf -- '- No se incluyen sha256sums (decision confirmada). Verificacion post-restore comparando paths y arboles de archivos.\n'
    printf -- '- El backup NO esta comprimido. Para comprimir a `.tar.zst`: `tar --zstd -cf devuan-backup.tar.zst backup/` (lo haces vos manualmente).\n'
} >> "$MANIFEST"

printf 'MANIFEST generado en %s\n' "$MANIFEST"