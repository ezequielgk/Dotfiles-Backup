#!/usr/bin/env bash
PRIMARY="{{colors.primary.default.hex}}"
SECONDARY="{{colors.secondary.default.hex}}"
COLOR="${PRIMARY:1}"
COLOR2="${SECONDARY:1}"
THEME_NAME="Noctalia-Reversal-dark"
THEME_DIR="$HOME/.icons/$THEME_NAME"
BRANCH="color-${COLOR}-${COLOR2}"

hex_darken() {
    local hex="${1}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf "%02x%02x%02x" $(( r*65/100 )) $(( g*65/100 )) $(( b*65/100 ))
}
COLOR_DARK=$(hex_darken "$COLOR")

if git -C "$THEME_DIR" show-ref --quiet "refs/heads/$BRANCH"; then
    git -C "$THEME_DIR" checkout -q "$BRANCH"
else
    git -C "$THEME_DIR" checkout -q main 2>/dev/null || git -C "$THEME_DIR" checkout -q master 2>/dev/null
    git -C "$THEME_DIR" checkout -q "original" -- .
    git -C "$THEME_DIR" add -A
    git -C "$THEME_DIR" commit -q --allow-empty -m "restored"
    git -C "$THEME_DIR" checkout -q -b "$BRANCH"
    
    # Reversal usa #f5aa1e, #f08705, #ffc841 para sus carpetas naranjas
    find "$THEME_DIR" -name "*.svg" -path "*/places/*" -type f -print0 | xargs -0 -P $(nproc) sed -i \
        -e "s/#f5aa1e/#${COLOR}/gI" \
        -e "s/#f08705/#${COLOR_DARK}/gI" \
        -e "s/#ffc841/#${COLOR2}/gI"
        
    git -C "$THEME_DIR" commit -q -am "color $BRANCH"
fi

gtk-update-icon-cache -f -t "$THEME_DIR" 2>/dev/null
CURRENT=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
if [[ "$CURRENT" == "$THEME_NAME" ]]; then
    gsettings set org.gnome.desktop.interface icon-theme "hicolor" 2>/dev/null
    sleep 0.3
    gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME" 2>/dev/null
else
    gsettings set org.gnome.desktop.interface icon-theme "$THEME_NAME" 2>/dev/null
fi
