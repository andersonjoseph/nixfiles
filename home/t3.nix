{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let
  isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);
  isVondel = nixosConfig.networking.hostName == "vondel";
in
{
  programs.t3code = lib.mkIf isDesktopMachine {
    enable = true;
    package = pkgs.t3-server;
  };

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
