#!/bin/sh
# 04b-audio.sh — install PipeWire + WirePlumber for audio.
# PipeWire runs as a per-user session service (no systemd here); it is started
# by the lines already present in ~/.config/mango/autostart.sh (restored via the
# 'wm' backup category). D-Bus activation may also start them on demand.
set -eu

PACKAGES="pipewire pipewire-audio wireplumber pipewire-pulse pipewire-alsa"

missing=0
for pkg in $PACKAGES; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        missing=1
        break
    fi
done

if [ "$missing" -eq 1 ]; then
    # shellcheck disable=SC2086
    sudo apt install -y $PACKAGES
    echo "04b: PipeWire + WirePlumber instalados"
else
    echo "04b: todos los paquetes de audio ya instalados"
fi

cat <<EOF

04b: audio listo.
Arranque: el autostart.sh de Mango (restaurado desde categoria 'wm' del backup)
ya levanta pipewire, wireplumber y pipewire-pulse con '&'. Si Mango abre sesion
via dbus-run-session, tambien pueden autoactivarse sin esas lineas.
Verificar tras logear (con compositor corriendo):

  pactl info                # deberia listr Default Sample Rate, no "Connection failed"
  wpctl status              # tree de sinks/sources
  pw-cli info 0             # responde si el demonio esta arriba

EOF