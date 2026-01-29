{ pkgs, ... }:
{

  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;

  boot.tmp.useTmpfs = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024; # 16GB
    }
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "vondel";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Caracas";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.anderson = {
    isNormalUser = true;
    description = "anderson";
    initialHashedPassword = "$6$k2/MT8SgzcASeb4W$5N9Z7D114THiK47xMbo0RDt.dXJkeROI4t.55C087sTas8wIYIO5xjHVrNaHUkO4QQ0E4vBNgF1YnkS7EYOQa0";
    extraGroups = [
      "networkmanager"
      "wheel"
      "nordvpn"
    ];
  };

  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      UseDns = true;
      PasswordAuthentication = true;
    };
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8080;
    openFirewall = true;
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

  services.journald.extraConfig = "SystemMaxUse=1G";

  networking.firewall.allowedTCPPorts = [
    22
    8080
  ];

  environment.systemPackages = with pkgs; [
    htop
    git
    vim
    jq
    ripgrep
  ];

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "23.05";
}
