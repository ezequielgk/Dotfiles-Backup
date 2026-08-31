#!/usr/bin/env bash

dir="$(xdg-user-dir VIDEOS)/Recordings"
mkdir -p "$dir"

pidfile="/tmp/wf-recorder.pid"

if [ -f "$pidfile" ]; then
    kill -INT "$(cat "$pidfile")"
    rm -f "$pidfile"
    notify-send "Grabación detenida" "Guardando video..."
    exit 0
fi

file="$(date +'%Y-%m-%d_%H-%M-%S').mp4"
path="$dir/$file"

wf-recorder --audio="$(pactl get-default-sink).monitor" -f "$path" &
echo $! > "$pidfile"

notify-send "Grabación iniciada" "$file"
