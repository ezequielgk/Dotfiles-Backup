#!/usr/bin/env bash
PRIMARY="{{colors.primary.default.hex}}"
SECONDARY="{{colors.secondary.default.hex}}"
COLOR="${PRIMARY:1}"
COLOR2="${SECONDARY:1}"
THEME_NAME="Noctalia-Vimix-dark"
THEME_DIR="$HOME/.icons/$THEME_NAME"
BRANCH="color-${COLOR}-${COLOR2}"

if git -C "$THEME_DIR" show-ref --quiet "refs/heads/$BRANCH"; then
    git -C "$THEME_DIR" checkout -q "$BRANCH"
else
    git -C "$THEME_DIR" checkout -q main 2>/dev/null || git -C "$THEME_DIR" checkout -q master 2>/dev/null
    git -C "$THEME_DIR" checkout -q "original" -- .
    git -C "$THEME_DIR" add -A
    git -C "$THEME_DIR" commit -q --allow-empty -m "restored"
    git -C "$THEME_DIR" checkout -q -b "$BRANCH"
    
    # Vimix utiliza ColorScheme-Highlight para sus colores base
    find "$THEME_DIR" -name "*.svg" -path "*/places/*" -type f -print0 | xargs -0 -P $(nproc) sed -i \
        -e "s/\.ColorScheme-Highlight { color:#[0-9a-fA-F]\{6\}/\.ColorScheme-Highlight { color:#${COLOR}/gI" \
        -e "s/\.ColorScheme-Text { color:#[0-9a-fA-F]\{6\}/\.ColorScheme-Text { color:#${COLOR2}/gI"
        
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
