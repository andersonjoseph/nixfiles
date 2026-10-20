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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC94m5sA5JJQ+n4UYoUCiT1YNYxsmTYFjk1wYupVesna ashika->vondel"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsL1q7SJiMvj1pkm7d/lzX9hPhEa2wjkAi6rA/hN4Vo lyndon->vondel"
  ];

  users.users.anderson.linger = true;

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

  services.journald.extraConfig = "SystemMaxUse=1G";

  services.eternal-terminal.enable = true;

  networking.firewall.trustedInterfaces = [ "docker0" ];

  networking.firewall.allowedTCPPorts = [
    22

    8000
    2022
  ];

  environment.systemPackages = with pkgs; [
    htop
    git
    vim
  ];
}
