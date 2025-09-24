{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/default.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "almazrah";
}
