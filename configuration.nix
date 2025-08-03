# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  environment.pathsToLink = [ "/libexec" ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "ashika"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Caracas";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_VE.UTF-8";
    LC_IDENTIFICATION = "es_VE.UTF-8";
    LC_MEASUREMENT = "es_VE.UTF-8";
    LC_MONETARY = "es_VE.UTF-8";
    LC_NAME = "es_VE.UTF-8";
    LC_NUMERIC = "es_VE.UTF-8";
    LC_PAPER = "es_VE.UTF-8";
    LC_TELEPHONE = "es_VE.UTF-8";
    LC_TIME = "es_VE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.anderson = {
    isNormalUser = true;
    description = "anderson";
    extraGroups = [ "networkmanager" "wheel"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # we need this to allow eddie to be installed 
  # https://github.com/NixOS/nixpkgs/pull/332532
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-sdk-6.0.36"
    "dotnet-sdk-6.0.428"
    "dotnet-runtime-6.0.36"
  ];

  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];


  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [
     fzf
     neovim
     xclip
     pulseaudio
     brightnessctl
     bc
     tree
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.terminess-ttf
  ];

  programs.i3lock.enable = true;

  # List services that you want to enable:

  services.openssh.enable = true;
  services.upower.enable = true;

# make palm rejection work with keyd
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd virtual keyboard
    AttrKeyboardIntegration=internal
  '';

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        # https://github.com/rvaiya/keyd/blob/master/docs/keyd.scdoc
        # play with it by
        # sudo bash -c 'cd /etc/keyd; cp -H default.conf t;mv -f t default.conf; chown wmertens default.conf'
        # and then edit /etc/keyd/default.conf + restart keyd
        # (be sure to retain the ids section at the top!)
        extraConfig = ''
	  [main]
	  capslock = overload(capslock-layer, esc)

	  [shift]
	  esc = ~

	  [capslock-layer:C]

	  space = backspace

          # movement
	  h = left
	  k = up
	  j = down
	  l = right

	  [capslock-layer+shift]
	  space = C-backspace
	'';
      };
    };
  };

  services.xserver = {
    enable = true;
    windowManager.i3.enable = true;
  };
  services.displayManager.defaultSession = "none+i3";
  security.pam.services = {
    i3lock.enable = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  system.autoUpgrade.enable = true;
  system.autoUpgrade.dates = "weekly";
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;
}
