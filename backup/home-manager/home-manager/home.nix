{ config, pkgs, lib, inputs, ... }:
let
  # Si ya tenés `nixgl` declarado como input en tu flake.nix, es preferible usar:
  #   nixgl = inputs.nixgl.packages.${pkgs.system};
  # así queda fijado por flake.lock en vez de bajar `main` sin pin/hash cada vez.
  nixgl = import (builtins.fetchTarball "https://github.com/nix-community/nixGL/archive/main.tar.gz") {};

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
exec ${nixgl.auto.nixGLDefault}/bin/nixGLDefault "$wrapped" "\$@"
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
    
    nixgl.auto.nixGLDefault
    inputs.concord.packages.${pkgs.system}.default
    
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
  };
}
