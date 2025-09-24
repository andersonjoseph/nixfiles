{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/default.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;

  fileSystems."/mnt/dos" = {
    device = "/dev/disk/by-uuid/479c69de-544c-4061-8aa3-666a57e71d4c";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  networking.hostName = "almazrah";
}
