{
  lib,
  nordvpn-cli,
  nordvpn-gui,
  symlinkJoin,
}:
symlinkJoin {
  pname = "nordvpn";
  inherit (nordvpn-cli) version;

  paths = [
    nordvpn-cli
    nordvpn-gui
  ];

  meta = nordvpn-cli.meta // {
    description = "NordVPN cli and gui applications for Linux.";
  };
}
