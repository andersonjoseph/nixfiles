{
  pkgs,
  lib,
  config,
  nixosConfig,
  ...
}:
let
  isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);
  isVondel = nixosConfig.networking.hostName == "vondel";

  # The AppImage ships only the desktop app; the CLI and server come from the
  # source build, linked one binary at a time so its desktop entry and
  # t3code-desktop binary stay out of the environment.
  t3-cli = pkgs.runCommand "t3-cli" { } ''
    mkdir -p $out/bin $out/share
    ln -s ${pkgs.t3-server}/bin/t3 $out/bin/t3
    ln -s ${pkgs.t3-server}/share/bash-completion $out/share/bash-completion
    ln -s ${pkgs.t3-server}/share/fish $out/share/fish
    ln -s ${pkgs.t3-server}/share/zsh $out/share/zsh
  '';

  # The server's preview downloads a generic-Linux chrome-headless-shell into
  # ~/.t3/tools. The FHS env gives it a loader and the libraries it links
  # against, for the t3 server only.
  t3-server-fhs = pkgs.buildFHSEnv {
    name = "t3-server-fhs";
    targetPkgs =
      pkgs: with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        glib
        libdrm
        libgbm
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        nspr
        nss
        pango
        systemd
      ];
    runScript = "${pkgs.t3-server}/bin/t3";
  };
in
{
  home.packages = lib.optionals isDesktopMachine [
    pkgs.t3-desktop
    t3-cli
  ];

  # T3 Code writes its default rules into this file at startup. The write
  # follows the symlink, so the defaults land in the checkout.
  home.file.".t3/userdata/keybindings.json" = lib.mkIf isDesktopMachine {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/t3/keybindings.json";
  };

  # vondel runs the shared t3 server on the tailnet; the other hosts connect.
  systemd.user.services.t3code = lib.mkIf isVondel {
    Unit = {
      Description = "T3 Code server";
      After = [ "network-online.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${t3-server-fhs}/bin/t3-server-fhs serve --host 100.88.47.99 --port 3773";
      Restart = "on-failure";
    };
  };
}
