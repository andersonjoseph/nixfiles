{
  pkgs,
  nixosConfig,
  ...
}:
let
  inboxPorts = {
    lyndon = "45585";
    vondel = "45586";
  };
  inboxPort = inboxPorts.${nixosConfig.networking.hostName} or null;
in
{
  systemd.user.services.plannotator-inbox = {
    Unit.Description = "Plannotator Inbox";
    Service =
      {
        ExecStart = "${pkgs.plannotator}/bin/plannotator inbox --no-open";
        Restart = "on-failure";
        RestartSec = 5;
      }
      // pkgs.lib.optionalAttrs (inboxPort != null) {
        Environment = "PLANNOTATOR_PORT=${inboxPort}";
      };
    Install.WantedBy = [ "default.target" ];
  };
}
