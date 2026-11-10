{
  lib,
  pkgs,
  nixosConfig,
  ...
}:
{
  systemd.user.services.tunnel-vondel = lib.mkIf (nixosConfig.networking.hostName == "lyndon") {
    Unit.Description = "SSH tunnel to vondel-nord";
    Service = {
      ExecStart = "${pkgs.openssh}/bin/ssh -N -T vondel-tunnel";
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
