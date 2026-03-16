{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDesktopMachine = builtins.elem config.networking.hostName [ "almazrah" "ashika" ];
in
{
  imports = [
    ./../../options.nix
  ];

  virtualisation.docker = {
    enable = true;
  };

  environment.pathsToLink = [ "/libexec" ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Caracas";
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

  services.pipewire = lib.mkIf isDesktopMachine {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

  security.pki.certificateFiles = [
    ./vondel.crt
  ];

  hardware.alsa.enablePersistence = lib.mkIf isDesktopMachine true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.pulseaudio.enable = lib.mkIf isDesktopMachine false;
  services.gvfs.enable = lib.mkIf isDesktopMachine true;
  services.tumbler.enable = lib.mkIf isDesktopMachine true;

  services.libinput = lib.mkIf isDesktopMachine {
    enable = true;
    touchpad = {
      naturalScrolling = true;
    };
  };

  users.users.anderson = {
    isNormalUser = true;
    description = "anderson";
    extraGroups = [
      "networkmanager"
      "wheel"
      "nordvpn"
      "docker"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;

  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [
    pulseaudio
  ];

  fonts = lib.mkIf isDesktopMachine {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.iosevka
    ];

    fontconfig = {
      antialias = true;

      hinting = {
        enable = true;
        style = "full";
        autohint = true;
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };
  };

  programs.i3lock.enable = lib.mkIf isDesktopMachine true;
  programs.ssh.startAgent = true;

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
    };
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.upower.enable = true;

  environment.etc = lib.mkIf isDesktopMachine {
    "libinput/local-overrides.quirks".text = ''
      [Serial Keyboards]
      MatchUdevType=keyboard
        MatchName=keyd virtual keyboard
        AttrKeyboardIntegration=internal
    '';
  };

  services.keyd = lib.mkIf isDesktopMachine {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = lib.mkMerge [
            {
              capslock = "overload(capslock-layer, esc)";
            }

            (lib.mkIf (config.custom.hasNvidia) {
              esc = "`";
              backspace = "noop";
            })

            (lib.mkIf (config.networking.hostName == "ashika") {
              delete = "noop";
            })
          ];

          shift = {
            esc = "~";
          };

          "capslock-layer:C" = {
            space = "backspace";
            h = "left";
            k = "up";
            j = "down";
            l = "right";
            backspace = "delete";
          };
        };

        extraConfig = ''
          [capslock-layer+shift]
          space = C-backspace
        '';
      };
    };
  };

  services.xserver = lib.mkIf isDesktopMachine {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    windowManager.i3.enable = true;
  };
  services.displayManager.defaultSession = lib.mkIf isDesktopMachine "none+i3";
  security.pam.services = lib.mkIf isDesktopMachine {
    i3lock.enable = true;
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  system.stateVersion = "25.05";
}
