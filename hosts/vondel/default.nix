{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/default.nix
  ];

  networking.hostName = "vondel";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;

  users.users.anderson.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID4RQrSTll/Ugui6ty+c6XvBCPYHT9OMm7F1K4KeTiCC almazrah->vondel"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC94m5sA5JJQ+n4UYoUCiT1YNYxsmTYFjk1wYupVesna ashika->vondel"
  ];

  services.open-webui = {
    enable = true;
    port = 3000;
  };

  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/*.log" = {
        daily = true;
        rotate = 30;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."vondel-nord.nord:8000".extraConfig = ''
      tls internal
      reverse_proxy localhost:3000
    '';
  };

  services.journald.extraConfig = "SystemMaxUse=1G";

  services.eternal-terminal.enable = true;

  networking.firewall.trustedInterfaces = [ "docker0" ];

  networking.firewall.allowedTCPPorts = [
    22
    80
    443

    8000
    2022
  ];

  environment.systemPackages = with pkgs; [
    htop
    git
    vim
  ];
}
