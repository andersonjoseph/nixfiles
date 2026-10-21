{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let
  isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);
  isVondel = nixosConfig.networking.hostName == "vondel";

  # The AppImage ships only the desktop app; the CLI and server come from the
  # source build, exposed without its duplicate desktop entry.
  t3-cli = pkgs.runCommand "t3-cli" { } ''
    mkdir -p $out
    ln -s ${pkgs.t3-server}/bin $out/bin
    ln -s ${pkgs.t3-server}/share $out/share
  '';
in
{
  home.packages = lib.optionals isDesktopMachine [
    pkgs.t3-desktop
    t3-cli
  ];

  systemd.user.services.t3code = lib.mkIf isVondel {
    Unit = {
      Description = "T3 Code server";
      After = [ "network-online.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${pkgs.t3-server}/bin/t3 serve --host 100.88.47.99 --port 3773";
      Restart = "on-failure";
    };
  };
}
