#!/usr/bin/env bash

dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dir"

file="$(date +'%Y-%m-%d_%H-%M-%S').png"
path="$dir/$file"

if grim "$path"; then
    wl-copy < "$path"
    
    notify-send -i "$path" "Captura completa guardada" "$file\nCopiada al portapapeles."
else
    notify-send -u critical "Error" "No se pudo tomar la captura completa."
fi
