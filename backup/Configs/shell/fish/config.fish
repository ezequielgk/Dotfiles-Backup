set fish_greeting

# 1. RUTAS XDG Y VARIABLES DE ENTORNO
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_STATE_HOME "$HOME/.local/state"
set -gx XDG_CACHE_HOME "$HOME/.cache"
# XDG_CURRENT_DESKTOP ya se define en home.nix (home.sessionVariables), no lo dupliques acá.

# Orden de PATH: se antepone en orden inverso al de las llamadas,
# así que la última llamada gana prioridad máxima.
# Prioridad final (mayor a menor): ~/.cargo/bin > ~/.local/bin > ~/.nix-profile/bin > /nix/var/nix/profiles/default/bin
fish_add_path /nix/var/nix/profiles/default/bin
fish_add_path $HOME/.nix-profile/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin

# Configuración de Nix
if not contains $HOME/.nix-defexpr/channels $NIX_PATH
    set -gx NIX_PATH $NIX_PATH $HOME/.nix-defexpr/channels
end
set -gx NIX_CONFIG "experimental-features = nix-command flakes"

# Asegurar que las aplicaciones locales estén en XDG_DATA_DIRS
if test -z "$XDG_DATA_DIRS"
    set -gx XDG_DATA_DIRS /usr/local/share:/usr/share
end
if not string match -q "*$HOME/.local/share/applications*" -- "$XDG_DATA_DIRS"
    set -gx XDG_DATA_DIRS $HOME/.local/share/applications:$XDG_DATA_DIRS
end

# 2. ALIAS
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --icons'
alias lla='eza -lah --icons --group-directories-first'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias update='sudo apt update && sudo apt upgrade'
alias search='apt search'
alias ff='clear && fastfetch'
alias pp='clear && pfetch'
alias clone='git clone'
alias setbrowser='xdg-settings set default-web-browser'
alias mc='cd ~/Descargas/SV\ mc/sv && nix-shell'
alias sumem='sudo (which ps_mem)'
alias nixs='home-manager switch'
alias home='cd ~'
alias da='dash -c'
alias ba='bash -c'
alias mx='chmod +x'
alias p="ps aux | grep -i"
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
alias rmpc="mpd-ensure rmpc"


# 3. FUNCIONES ÚTILES

function extract
    argparse 'p/password=' -- $argv
    or return

    for archive in $argv
        if not test -f "$archive"
            echo "'$archive' no es un archivo válido."
            continue
        end

        switch "$archive"
            case '*.tar.bz2'
                tar xvjf "$archive"
            case '*.tar.gz'
                tar xvzf "$archive"
            case '*.tar.xz'
                tar xvJf "$archive"
            case '*.xz'
                unxz "$archive"
            case '*.bz2'
                bunzip2 "$archive"
            case '*.rar'
                if set -q _flag_password
                    unrar x -p"$_flag_password" "$archive"
                else
                    unrar x "$archive"
                end
            case '*.gz'
                gunzip "$archive"
            case '*.tar'
                tar xvf "$archive"
            case '*.tbz2'
                tar xvjf "$archive"
            case '*.tgz'
                tar xvzf "$archive"
            case '*.zip'
                if set -q _flag_password
                    unzip -P "$_flag_password" "$archive"
                else
                    unzip "$archive"
                end
            case '*.Z'
                uncompress "$archive"
            case '*.7z'
                if set -q _flag_password
                    7z x -p"$_flag_password" "$archive"
                else
                    7z x "$archive"
                end
            case '*'
                echo "No sé cómo extraer '$archive'..."
                continue
        end

        if test $status -ne 0
            echo "Error extrayendo '$archive' (¿contraseña incorrecta o faltante?)"
        end
    end
end

function mkdirg
    mkdir -p "$argv[1]"; and cd "$argv[1]"
end

function up
    set -l limit 1
    if set -q argv[1]
        set limit $argv[1]
    end
    set -l d ""
    for i in (seq 1 $limit)
        set d "$d/.."
    end
    cd $d
end

function lazyg
    if not set -q argv[1]
        echo "Uso: lazyg \"Mensaje del commit\""
        return 2
    end
    git add .
    git commit -m "$argv[1]"
    git push
end

function clickpaste
    set -l sleep_time 3
    if set -q argv[1]
        set sleep_time $argv[1]
    end
    sleep $sleep_time
    wl-paste | wtype -
end

# 4. INTEGRACIONES (Deben ir al final)
# Ejecutar esto solo si la sesión es interactiva
if status is-interactive
    # Zoxide (Navegación inteligente)
    if type -q zoxide
        zoxide init fish | source
        # Atajo Ctrl+F para lanzar el buscador interactivo (zi)
        bind \cf 'zi; commandline -f repaint'
    end
    # Prompt de Starship
    if type -q starship
        starship init fish | source
    end
end

function pkgs-export --description "Exporta la lista de paquetes instalados (dpkg --get-selections)"
    set -l destino ~/paquetes-instalados.txt

    if test (count $argv) -gt 0
        set destino $argv[1]
    end

    dpkg --get-selections > $destino
    echo "Lista exportada a: $destino"
end

function pkgs-restore --description "Restaura paquetes desde un archivo de selecciones dpkg"
    set -l origen ~/paquetes-instalados.txt

    if test (count $argv) -gt 0
        set origen $argv[1]
    end

    if not test -f $origen
        echo "No se encontró el archivo: $origen"
        return 1
    end

    echo "Restaurando selecciones desde: $origen"
    sudo dpkg --set-selections < $origen
    sudo apt-get dselect-upgrade
end


# opencode
fish_add_path /home/ezequiel/.opencode/bin
