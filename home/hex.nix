{ pkgs, ... }:
{
  programs.hex = {
    enable = true;
    package = pkgs.hex;
  };
}
