#!/bin/sh
# Backup the 7 user-owned categories with cp -a, one git commit per category.
# Idempotent: skips categories already present in the backup tree.
set -eu

BACKUP="${HOME}/devuan-migration/backup"
SCRIPTS="${HOME}/devuan-migration/scripts"
cd "$BACKUP"

# Initialize git repo if needed.
if [ ! -d "$BACKUP/.git" ]; then
    git init -q
    git config user.email "devuan-migration@local"
    git config user.name "devuan-migration"
    echo "git repo inicializado en $BACKUP"
else
    echo "git repo ya existe, continuando"
fi

# Helper: copy one source into a category dir if not already present.
#   copy_src <category> <src_path> <dest_subpath>
# dest_subpath is relative to $BACKUP/<category>/
copy_src() {
    cat_name="$1"
    src="$2"
    dest_sub="$3"
    dest="$BACKUP/$cat_name/$dest_sub"

    if [ ! -e "$src" ]; then
        printf '   -- saltando (no existe): %s\n' "$src"
        return 0
    fi

    base=$(basename "$src")
    target="$dest/$base"

    if [ -e "$target" ]; then
        printf '   == ya respaldado: %s -> %s\n' "$src" "$target"
        return 0
    fi

    mkdir -p "$dest"
    # cp -a: preserve mode, ownership (best-effort for user files), symlinks, timestamps.
    cp -a "$src" "$dest/"
    printf '   OK copiado: %s -> %s\n' "$src" "$target"
}

# Process a category: copy sources, stage, commit.
#   do_category <name> <commit_msg> <src1> <src2> ...
do_category() {
    name="$1"
    msg="$2"
    shift 2
    printf '\n>> Categoria: %s\n' "$name"
    for src in "$@"; do
        copy_src "$name" "$src" ""
    done
    git add "$BACKUP/$name" 2>/dev/null || true
    if git diff --cached --quiet 2>/dev/null; then
        printf '   (sin cambios nuevos, no se committea)\n'
    else
        git commit -q -m "$msg"
        printf '   commit: %s\n' "$msg"
    fi
}

do_category wm           "backup: wm config (sway + mango)" \
    "${HOME}/.config/sway" "${HOME}/.config/mango"

do_category terminal     "backup: terminal config (foot)" \
    "${HOME}/.config/foot"

do_category shell        "backup: shell config (fish)" \
    "${HOME}/.config/fish"

do_category noctalia     "backup: noctalia config + state" \
    "${HOME}/.config/noctalia" "${HOME}/.local/state/noctalia"

# portal: keep .config, skip /etc (absent).
do_category portal       "backup: xdg-desktop-portal config" \
    "${HOME}/.config/xdg-desktop-portal"

do_category home-manager "backup: home-manager flake" \
    "${HOME}/.config/home-manager"

# appearance: themes + icons + fonts (big).
do_category appearance   "backup: appearance (themes + icons + fonts)" \
    "${HOME}/.local/share/themes" "${HOME}/.local/share/icons" "${HOME}/.local/share/fonts"

printf '\nListo backup no-sudo. Faltan emptty y pam (requieren sudo).\n'
printf 'Correr: sudo bash %s/sudo-backup.sh\n' "$SCRIPTS"