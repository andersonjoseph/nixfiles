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
      Environment = [ "SIDESHOW_HOST=127.0.0.1" ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
