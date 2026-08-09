#!/bin/sh
# Precheck: list source paths per category, report missing ones, compute sizes.
# No copy, no sudo. Read-only inspection.
set -eu

# category_name|needs_sudo|src1 src2 ...
CATS='
wm|no|'"${HOME}"'/.config/sway '"${HOME}"'/.config/mango
terminal|no|'"${HOME}"'/.config/foot
shell|no|'"${HOME}"'/.config/fish
noctalia|no|'"${HOME}"'/.config/noctalia '"${HOME}"'/.local/state/noctalia
portal|no|'"${HOME}"'/.config/xdg-desktop-portal '"${HOME}"'/__dummy__/xdg-desktop-portal-etc
home-manager|no|'"${HOME}"'/.config/home-manager
appearance|no|'"${HOME}"'/.local/share/themes '"${HOME}"'/.local/share/icons '"${HOME}"'/.local/share/fonts
emptty|yes|/etc/emptty/conf-tty7 /etc/emptty/motd
pam|yes|/etc/pam.d/emptty
'

# Note: /etc/xdg-desktop-portal is skipped here (confirmed absent in current system).

print_line() { printf '%s\n' "$1"; }

print_line "============================================================"
print_line "PRECHECK BACKUP - $(date '+%Y-%m-%d %H:%M:%S')"
print_line "============================================================"

# Process each non-empty line of CATS.
echo "$CATS" | grep -v '^$' | while IFS='|' read -r name needs_sudo srcs; do
    [ -z "$name" ] && continue
    print_line ""
    print_line ">> Categoria: ${name}  (sudo: ${needs_sudo})"
    cat_bytes=0
    cat_files=0
    cat_present=0
    for src in $srcs; do
        # Skip the dummy placeholder used to keep field count consistent.
        [ "$src" = "${HOME}/__dummy__/xdg-desktop-portal-etc" ] && continue
        if [ -e "$src" ]; then
            cat_present=$((cat_present + 1))
            if [ -d "$src" ]; then
                nfiles=$(find "$src" -type f 2>/dev/null | wc -l)
                nbytes=$(du -sb "$src" 2>/dev/null | awk '{print $1}')
            else
                nfiles=1
                nbytes=$(du -sb "$src" 2>/dev/null | awk '{print $1}')
            fi
            # Handle du failure on unreadable files: estimate 0 to avoid abort.
            [ -z "$nbytes" ] && nbytes=0
            [ -z "$nfiles" ] && nfiles=0
            cat_bytes=$((cat_bytes + nbytes))
            cat_files=$((cat_files + nfiles))
            printf '   OK   %12d B  %5d archivos  %s\n' "$nbytes" "$nfiles" "$src"
        else
            printf '   --   (no encontrado, salteado)  %s\n' "$src"
        fi
    done
    if [ "$cat_present" -gt 0 ]; then
        printf '   SUBTOTAL: %d B, %d archivos\n' "$cat_bytes" "$cat_files"
    else
        print_line "   SUBTOTAL: categoria vacia (ningun origen existe)"
    fi
done

print_line ""
print_line "============================================================"
print_line "Nota: los totales son informativos. /etc/xdg-desktop-portal"
print_line "      esta ausente y se saltea con nota en el MANIFEST."
print_line "      Las categorias 'emptty' y 'pam' requieren sudo para cp -a"
print_line "      (preservar ownership root:root)."
print_line "============================================================"