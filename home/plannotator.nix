{
  pkgs,
  ...
}:
{
  systemd.user.services.plannotator-inbox = {
    Unit.Description = "Plannotator Inbox";
    Service = {
      ExecStart = "${pkgs.plannotator}/bin/plannotator inbox --no-open";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
