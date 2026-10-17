# T3 Code on the headless vondel server: CLI tools for pairing/auth plus an
# always-on `t3 serve` systemd user service, exposed on the NordVPN meshnet
# (port 45860; the nordlynx-scoped firewall rule lives in hosts/common).
# Desktop hosts keep using the AppImage with its Settings > Connections
# network-access toggle instead of this service.
{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
{
  config = lib.mkIf (nixosConfig.networking.hostName == "vondel") {
    home.packages = with pkgs; [
      t3-cli # `t3` binary: t3 pair / t3 auth / t3 app
      t3-serve # PATH-fixing launcher the service below runs
    ];

    # Kept alive across logouts/reboots via users.users.anderson.linger
    # (hosts/vondel). Providers are the jailed claude/pi shims t3-serve puts
    # on PATH; state lives in ~/.t3/userdata.
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
