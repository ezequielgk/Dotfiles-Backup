#!/bin/sh
# 06-emptty.sh — install emptty and hand-build its runit service dir.
# Devuan doesn't ship an emptty runit service so we build it like the user's
# current setup: foreground emptty on the configured tty, logging via svlogd.
set -eu

if ! dpkg -s emptty >/dev/null 2>&1; then
    sudo apt install -y emptty
    echo "06: emptty instalado"
else
    echo "06: emptty ya instalado"
fi

SV_DIR="/etc/sv/emptty"
LOG_DIR="/var/log/emptty"
ENABLED="/etc/runit/runsvdir/default/emptty"

# Build service dir if missing.
if [ ! -d "$SV_DIR" ]; then
    sudo mkdir -p "$SV_DIR/log"
    sudo tee "$SV_DIR/run" >/dev/null <<'EOF'
#!/bin/sh
exec /usr/bin/emptty
EOF
    sudo chmod +x "$SV_DIR/run"

    sudo tee "$SV_DIR/log/run" >/dev/null <<EOF
#!/bin/sh
exec svlogd -tt $LOG_DIR
EOF
    sudo chmod +x "$SV_DIR/log/run"

    sudo mkdir -p "$LOG_DIR"
    echo "06: service dir $SV_DIR creado (run + log/run)"
else
    echo "06: service dir $SV_DIR ya existe"
fi

# Enable (idempotent symlink).
if [ ! -L "$ENABLED" ]; then
    sudo ln -s "$SV_DIR" "$ENABLED"
    echo "06: emptty habilitado en runsvdir/default"
else
    echo "06: emptty ya habilitado"
fi

# Status hint (best-effort; sv may need a few seconds to register).
sudo sv status emptty 2>&1 || echo "06: sv status no respondio (el supervisor puede tardar unos segundos en levantarlo)"

echo "06: recorda restaurar /etc/emptty/conf-tty7 desde la categoria 'emptty' del backup"