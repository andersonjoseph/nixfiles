{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let
  isVondel = nixosConfig.networking.hostName == "vondel";
in
{
  programs.t3code = lib.mkIf isVondel {
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
      ExecStart = "${pkgs.t3-server}/bin/t3 serve";
      Restart = "on-failure";
    };
  };
}
