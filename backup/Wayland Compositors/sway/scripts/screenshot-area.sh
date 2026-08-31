#!/usr/bin/env bash

dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dir"

file="$(date +'%Y-%m-%d_%H-%M-%S').png"
path="$dir/$file"

area=$(slurp 2>/dev/null)
if [ -z "$area" ]; then
    exit 0
fi

if grim -g "$area" "$path"; then
    wl-copy < "$path"
    
    notify-send -i "$path" "Captura de Pantalla" "$file\nCopiada al portapapeles."
else
    notify-send -u critical "Error" "No se pudo tomar la captura."
fi
