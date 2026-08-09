#!/bin/sh
# 08b-polkit.sh — install policykit-1 + elogind + dbus. Without systemd, elogind
# tracks sessions so polkitd can authorize. polkitd itself is D-Bus-activated
# (no runit service needed). dbus and elogind need runit services enabled.
# Devuan ships their service dirs in either /etc/sv/ or /usr/share/runit/sv.current/
# so we detect and link the right one; if missing, build one by hand (emptty style).
set -eu

install_pkg() {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        sudo apt install -y "$1"
        echo "08b: $1 instalado"
    else
        echo "08b: $1 ya instalado"
    fi
}

install_pkg policykit-1
install_pkg elogind
install_pkg libpam-elogind
install_pkg dbus

# Resolve where a service dir lives (returns the dir path or empty).
resolve_sv() {
    name="$1"
    if [ -d "/etc/sv/$name" ]; then
        printf '/etc/sv/%s\n' "$name"
    elif [ -d "/usr/share/runit/sv.current/$name" ]; then
        printf '/usr/share/runit/sv.current/%s\n' "$name"
    else
        printf ''
    fi
}

# Enable an existing service, or build it from scratch if missing.
#   enable_service <name> <bin>
enable_service() {
    name="$1"
    bin="$2"
    logdir="/var/log/$name"
    enabled="/etc/runit/runsvdir/default/$name"

    if [ -L "$enabled" ]; then
        echo "08b: $name ya habilitado"
        return 0
    fi

    sv_dir=$(resolve_sv "$name")
    if [ -n "$sv_dir" ]; then
        sudo ln -s "$sv_dir" "$enabled"
        echo "08b: $name habilitado desde $sv_dir"
    else
        # Build service dir by hand (emptty style).
        sudo mkdir -p "/etc/sv/$name/log"
        sudo tee "/etc/sv/$name/run" >/dev/null <<EOF
#!/bin/sh
exec $bin
EOF
        sudo chmod +x "/etc/sv/$name/run"

        sudo tee "/etc/sv/$name/log/run" >/dev/null <<EOF
#!/bin/sh
exec svlogd -tt $logdir
EOF
        sudo chmod +x "/etc/sv/$name/log/run"

        sudo mkdir -p "$logdir"
        sudo ln -s "/etc/sv/$name" "$enabled"
        echo "08b: $name service dir creado a mano y habilitado"
    fi
}

# dbus runs the system bus (needed for polkitd D-Bus activation).
# elogind tracks sessions (needed for polkitd authorization).
enable_service dbus "/usr/bin/dbus-daemon --system --nofork --nopidfile"
enable_service elogind "/lib/elogind/elogind"

# Best-effort status hint.
sudo sv status dbus elogind 2>&1 || echo "08b: sv status no respondio (puede tardar unos segundos)"

cat <<EOF

08b: polkit + elogind + dbus listos.
  - polkitd NO necesita runit (D-Bus lo activa bajo demanda).
  - el agente de autenticacion ya lo trae Noctalia (no hace falta lxqt-policykit).
  - Verificar: sv status dbus elogind  &&  loginctl

EOF