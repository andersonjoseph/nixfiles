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

  networking.hostName = "almazrah";
}
