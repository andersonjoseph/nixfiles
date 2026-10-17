# T3 Code on vondel: an always-on `t3 serve` systemd user service on the
# NordVPN meshnet, port 45860 (nordlynx firewall rule in hosts/common).
# Desktop hosts use the AppImage's network-access toggle instead.
{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
{
  config = lib.mkIf (nixosConfig.networking.hostName == "vondel") {
    home.packages = with pkgs; [
      t3-cli
      t3-serve
    ];

    # Runs across logouts/reboots via users.users.anderson.linger
    # (hosts/vondel); state lives in ~/.t3/userdata.
    systemd.user.services.t3-serve = {
      Unit.Description = "T3 Code headless server";
      Service = {
        ExecStart = "${pkgs.t3-serve}/bin/t3-serve --mode web --host 0.0.0.0 --port 45860";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
