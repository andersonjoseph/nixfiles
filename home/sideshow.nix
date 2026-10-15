{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.sideshow ];

  systemd.user.services.sideshow = {
    Unit.Description = "Sideshow agent visual surface";
    Service = {
      ExecStart = "${pkgs.sideshow}/bin/sideshow serve";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [ "SIDESHOW_HOST=0.0.0.0" ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
