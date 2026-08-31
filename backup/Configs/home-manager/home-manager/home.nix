{ config, pkgs, lib, inputs, ... }:
let
  nixGLWrap = pkg: pkgs.symlinkJoin {
    name = "${pkg.pname or pkg.name}-nixgl";
    paths = [ pkg ];
    postBuild = ''
      for bin in "$out"/bin/*; do
        if [ -e "$bin" ]; then
          wrapped=$(readlink -f "$bin")
          rm -f "$bin"
          cat > "$bin" <<EOF
#!/bin/sh
exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa "$wrapped" "\$@"
EOF
          chmod +x "$bin"
        fi
      done
    '';
  };
in
{
  home.username = "ezequiel";
  home.homeDirectory = "/home/ezequiel";
  home.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    (pkgs.symlinkJoin {
      name = "gearlever-wrapped";
      paths = [ gearlever ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/gearlever \
          --prefix PATH : ${gearlever}/share/gearlever/gearlever/lib \
          --prefix PATH : ${squashfsTools}/bin
      '';
    })
    spotify
    appimage-run
    squashfsTools
    cowsay
    pipes-rs
    ranger
    rmpc
    mpd
    mpc
    mpdris2
    pkgs.nixgl.nixGLMesa
  ] ++ map nixGLWrap [
    brave
    goofcord
  ];

  home.file.".local/bin/get_appimage_offset" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      file="$1"
      magic=$(${pkgs.util-linux}/bin/od -A n -t x1 -j 8 -N 3 "$file" | tr -d ' \n')
      if [ "$magic" = "737173" ]; then
          echo 188
      else
          ${pkgs.binutils}/bin/readelf -l "$file" 2>/dev/null | awk '/LOAD/ { print $6; exit }'
      fi
    '';
  };

  home.file.".local/bin/mpd-ensure" = {
    executable = true;
    text = ''
      #!/bin/sh
      pgrep -x mpd >/dev/null || ${pkgs.mpd}/bin/mpd
      pgrep -f mpDris2 >/dev/null || setsid -f ${pkgs.mpdris2}/bin/mpDris2 >"$HOME/.cache/mpDris2.log" 2>&1
      exec "$@"
    '';
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
  };

  programs.home-manager.enable = true;

  home.activation = {
    linkDesktopApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.local/share/applications/
      $DRY_RUN_CMD find $HOME/.local/share/applications/ -type l -xtype l -delete
      $DRY_RUN_CMD ln -sfn ${config.home.profileDirectory}/share/applications/*.desktop $HOME/.local/share/applications/
    '';

    mpdDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $HOME/.config/mpd/playlists
    '';
  };

  xdg.configFile."mpd/mpd.conf".text = ''
    music_directory    "/mnt/Personal/Eze Linux/Musica"
    playlist_directory "~/.config/mpd/playlists"
    db_file            "~/.config/mpd/database"
    log_file           "~/.config/mpd/log"
    pid_file           "/run/user/1000/mpd.pid"
    state_file         "~/.config/mpd/state"
    sticker_file       "~/.config/mpd/sticker.sql"
    bind_to_address    "127.0.0.1"
    port               "6600"
    audio_output {
        type "pulse"
        name "PipeWire (via pulse shim)"
    }
    replaygain "auto"
  '';

  xdg.configFile."mpDris2/mpDris2.conf".text = ''
    [Connection]
    host = localhost
    port = 6600
    music_dir = /mnt/Personal/Eze Linux/Musica

    [Bling]
    progress = True
    mmkeys = True
    notify = True
  '';

  xdg.dataFile."dbus-1/services/org.mpris.MediaPlayer2.mpd.service".text = ''
    [D-BUS Service]
    Name=org.mpris.MediaPlayer2.mpd
    Exec=${pkgs.mpdris2}/bin/mpDris2
  '';
}
