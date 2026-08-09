#!/bin/sh
# Commit the sudo-backed categories (emptty, pam) to the backup git repo.
# Run with sudo: `sudo bash commit-sudo.sh`.
#
# Why sudo: the backup files keep their literal root:root ownership (mode 640
# for conf-tty7), which the unprivileged user cannot read. We chmod the
# intermediate dirs to 755 (they're synthetic, not literal) and run git as
# root. After committing, we hand .git back to the user so future git ops
# work without sudo.
set -eu

BACKUP="/home/ezequiel/devuan-migration/backup"
TARGET_USER="ezequiel"

# Make synthetic intermediate dirs traversable. Files inside keep literal mode.
chmod 755 "$BACKUP/emptty" "$BACKUP/emptty/etc" "$BACKUP/emptty/etc/emptty" 2>/dev/null || true
chmod 755 "$BACKUP/pam" "$BACKUP/pam/etc" "$BACKUP/pam/etc/pam.d" 2>/dev/null || true

cd "$BACKUP"

# Author identity for the commit (root has no git config by default).
export GIT_AUTHOR_NAME="devuan-migration"
export GIT_AUTHOR_EMAIL="devuan-migration@local"
export GIT_COMMITTER_NAME="devuan-migration"
export GIT_COMMITTER_EMAIL="devuan-migration@local"

for cat in emptty pam; do
    printf '\n>> Commit categoria: %s\n' "$cat"
    git add "$BACKUP/$cat" 2>/dev/null || true
    if git diff --cached --quiet 2>/dev/null; then
        printf '   (sin cambios nuevos para %s)\n' "$cat"
    else
        git commit -q -m "backup: ${cat} config (sudo, literal ownership)"
        printf '   commit: backup: %s config\n' "$cat"
    fi
done

# Hand .git back to the user so subsequent git ops work without sudo.
chown -R "$TARGET_USER:$TARGET_USER" "$BACKUP/.git"

printf '\nCommits de categorias sudo listos.\n'
printf 'Ahora podes verificar (como ezequiel): git -C %s log --oneline\n' "$BACKUP"