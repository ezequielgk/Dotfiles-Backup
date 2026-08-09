#!/bin/sh
# 10-zram-swap.sh — zram (8GB / 50% RAM, zstd, prio 100) + swapfile (8GB prio 10)
# + swappiness=150. zram absorbs most spikes; swapfile is a low-priority cushion
# for big peaks (cargo build + running game). Not for hibernation.
set -eu

# zram-tools
if ! dpkg -s zram-tools >/dev/null 2>&1; then
    sudo apt install -y zram-tools
    echo "10: zram-tools instalado"
else
    echo "10: zram-tools ya instalado"
fi

# /etc/default/zramswap (idempotent: only write if not configured).
ZSWAP_CONF="/etc/default/zramswap"
EXPECTED="PERCENT=50
ALGO=zstd
PRIORITY=100"
if [ ! -f "$ZSWAP_CONF" ] || ! sudo grep -q "^PERCENT=50" "$ZSWAP_CONF" 2>/dev/null; then
    printf '%s\n' "$EXPECTED" | sudo tee "$ZSWAP_CONF" >/dev/null
    echo "10: $ZSWAP_CONF escrito"
else
    echo "10: $ZSWAP_CONF ya configurado"
fi

# Restart (or enable) zramswap to pick up the new config.
if [ -L /etc/runit/runsvdir/default/zramswap ]; then
    sudo sv restart zramswap 2>&1 || echo "10: sv restart zramswap fallo (revisar)"
else
    # Enable zramswap service wherever its dir lives.
    # zram-tools on trixie ships only a systemd unit, not a runit service dir.
    # If no runit service exists, build it by hand (foreground /usr/sbin/zramswap
    # + svlogd logging) — same shape as emptty.
    ZRAM_BIN=/usr/sbin/zramswap
    SV_DIR=/etc/sv/zramswap
    ENABLED=/etc/runit/runsvdir/default/zramswap
    LOG_DIR=/var/log/zramswap

    if [ -L "$ENABLED" ]; then
        echo "10: zramswap ya habilitado"
    elif [ -d /etc/sv/zramswap ]; then
        sudo ln -s /etc/sv/zramswap /etc/runit/runsvdir/default/
        echo "10: zramswap habilitado desde /etc/sv/zramswap"
    elif [ -d /usr/share/runit/sv.current/zramswap ]; then
        sudo ln -s /usr/share/runit/sv.current/zramswap /etc/runit/runsvdir/default/
        echo "10: zramswap habilitado desde /usr/share/runit/sv.current/zramswap"
    elif [ -x "$ZRAM_BIN" ]; then
        # Build the service dir by hand.
        sudo mkdir -p "$SV_DIR/log"
        sudo tee "$SV_DIR/run" >/dev/null <<EOF
#!/bin/sh
exec $ZRAM_BIN
EOF
        sudo chmod +x "$SV_DIR/run"

        sudo tee "$SV_DIR/log/run" >/dev/null <<EOF
#!/bin/sh
exec svlogd -tt $LOG_DIR
EOF
        sudo chmod +x "$SV_DIR/log/run"

        sudo mkdir -p "$LOG_DIR"
        sudo ln -s "$SV_DIR" "$ENABLED"
        echo "10: zramswap service dir creado a mano en $SV_DIR y habilitado"
    else
        echo "10: WARNING: no encontre service dir de zramswap, ni el binario $ZRAM_BIN para construirlo. Abortando zram." >&2
        exit 1
    fi
fi

# Swapfile (idempotent via /etc/fstab check).
SWAPFILE="/swapfile"
if ! grep -q "^${SWAPFILE} " /etc/fstab 2>/dev/null; then
    if [ ! -f "$SWAPFILE" ]; then
        sudo fallocate -l 8G "$SWAPFILE"
        sudo chmod 600 "$SWAPFILE"
        sudo mkswap "$SWAPFILE"
    fi
    echo "$SWAPFILE none swap sw,pri=10 0 0" | sudo tee -a /etc/fstab >/dev/null
    sudo swapon -p 10 "$SWAPFILE" 2>/dev/null || true
    echo "10: swapfile creado, en fstab y activado"
else
    echo "10: swapfile ya en /etc/fstab"
fi

# Swappiness (zram as primary swap -> higher swappiness is fine, it's RAM).
SYSCTL_CONF="/etc/sysctl.d/99-zram.conf"
if [ ! -f "$SYSCTL_CONF" ] || ! sudo grep -q "^vm.swappiness=150" "$SYSCTL_CONF" 2>/dev/null; then
    echo "vm.swappiness=150" | sudo tee "$SYSCTL_CONF" >/dev/null
    sudo sysctl --system >/dev/null
    echo "10: $SYSCTL_CONF aplicado"
else
    echo "10: $SYSCTL_CONF ya configurado"
fi

echo "10: verificar con 'swapon --show' (esperado: /dev/zram0 prio 100 ~8G, /swapfile prio 10 8G)"