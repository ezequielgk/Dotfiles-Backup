#!/usr/bin/env bash
PRI="{{colors.primary.default.hex}}"
C1="${PRI:1}"
T_DIR="$HOME/.icons/Noctalia-Flat"
BRANCH="color-${C1}"

if git -C "$T_DIR" show-ref --quiet "refs/heads/$BRANCH"; then
    git -C "$T_DIR" checkout -q "$BRANCH"
else
    git -C "$T_DIR" checkout -q "original"
    git -C "$T_DIR" checkout -q -b "$BRANCH"
    
    hex_darken() {
        local hex="${1}"
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        printf "%02x%02x%02x" $(( r*65/100 )) $(( g*65/100 )) $(( b*65/100 ))
    }
    C_DARK=$(hex_darken "$C1")
    
    # MOTOR DE COLOR PRECISO
    find "$T_DIR" -name "*.svg" -type f -print0 | xargs -0 -P $(nproc) sed -i -E \
        -e "s/367bf0/${C1}/gI" \
        -e "s/2b62c0/${C_DARK}/gI" \
        -e "s/357af0/${C1}/gI" \
        -e "s/8c42ab/${C_DARK}/gI"
        
    git -C "$T_DIR" commit -q -am "color $BRANCH"
fi

gtk-update-icon-cache -f -t "$T_DIR" 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme "hicolor"
sleep 0.5
gsettings set org.gnome.desktop.interface icon-theme "Noctalia-Flat"
