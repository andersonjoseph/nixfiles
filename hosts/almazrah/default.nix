{ config, pkgs, ... }:

{
  imports = [
    # hardware-configuration.nix
    ../common/default.nix
  ];

  system = "x86_64-linux";
  networking.hostName = "almazrah";
}
