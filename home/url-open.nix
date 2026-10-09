{
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let
  port = 61413;
  isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);

  url-open = pkgs.writeShellScriptBin "url-open" ''
    url="$1"
    if printf '%s\n' "$url" | ${pkgs.socat}/bin/socat -T1 - TCP:127.0.0.1:${toString port}; then
      exit 0
    fi
    printf '%s\n' "no tunnel; open manually: $url"
    exit 1
  '';

  # socat runs this once per connection: read the URL line and hand it to
  # xdg-open on the desktop that owns the tunnel.
  url-open-handler = pkgs.writeShellScript "url-open-handler" ''
    read -r url
    exec ${pkgs.xdg-utils}/bin/xdg-open "$url"
  '';
in
{
  home.packages = [ url-open ] ++ (lib.optionals isDesktopMachine [ pkgs.xdg-utils ]);

  home.sessionVariables.BROWSER = "url-open";

  # Listens on the desktop only; a copy on vondel would steal the remote bind
  # of the RemoteForward and try to open a browser on a headless host.
  systemd.user.services.url-open-listener = lib.mkIf isDesktopMachine {
    Unit.Description = "Open URLs arriving from remote hosts over the url-open tunnel";
    Service.ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:${toString port},bind=127.0.0.1,fork,reuseaddr EXEC:${url-open-handler}";
    Install.WantedBy = [ "default.target" ];
  };
}
