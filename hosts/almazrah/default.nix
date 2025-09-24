{ config, pkgs, ... }:

{
  imports = [
    # hardware-configuration.nix
  ];

  system = "x86_64-linux";
  networking.hostName = "almazrah";
}
