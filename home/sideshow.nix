{
  pkgs,
  nixosConfig,
  ...
}:
let
  isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);
in
{
  home.packages = [ pkgs.sideshow ];

  systemd.user.services.sideshow = {
    Unit.Description = "Sideshow agent visual surface";
    Service = {
      ExecStart = "${pkgs.sideshow}/bin/sideshow serve";
      Restart = "on-failure";
      RestartSec = 5;
      # Desktops serve the LAN; headless hosts stay loopback behind the ssh forward.
      Environment = [ "SIDESHOW_HOST=${if isDesktopMachine then "0.0.0.0" else "127.0.0.1"}" ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
