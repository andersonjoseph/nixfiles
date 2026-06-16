{ pkgs, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/default.nix
  ];

  networking.hostName = "lyndon";
  custom.wallpaperFile = ../almazrah/wallpaper;
  custom.hasNvidia = true;

  # External monitor: mirror the laptop, run at 100Hz with full RGB range.
  custom.xrandr.startupCommand = ''
    xrandr --output DP-1 --same-as eDP-1 --mode 1920x1080 --rate 99.93 --set "Broadcast RGB" "Full"
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
	enable = true;
	enableOffloadCmd = true;
      };
      intelBusId  = "PCI:0:2:0";# from i915 0000:00:02.0
      nvidiaBusId = "PCI:1:0:0";# from nvidia 0000:01:00.0
    };
  };

  # Intel integrated graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  # battery life improvements
  powerManagement.powertop.enable = true;
  services = {
    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        STOP_CHARGE_THRESH_BAT0 = 95;
      };
    };
  };

  services.hardware.bolt.enable = true;
}
