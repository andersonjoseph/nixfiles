{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/default.nix
  ];

  networking.hostName = "almazrah";
  custom.wallpaperFile = ./wallpaper;

  custom.isDesktop = true;
  custom.hasNvidia = true;
  custom.xrandr.startupCommand = "xrandr --output HDMI-0 --mode 1920x1080 --rate 99.93";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;

  fileSystems."/mnt/dos" = {
    device = "/dev/disk/by-uuid/479c69de-544c-4061-8aa3-666a57e71d4c";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

}
