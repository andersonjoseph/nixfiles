{ config, pkgs, ... }:

{
  imports = [
    ./i3
    ./alacritty.nix
  ];

  home.stateVersion = "25.05";

  home.username = "anderson";
  home.homeDirectory = "/home/anderson";

  home.packages = with pkgs; [
    ripgrep
    vivaldi
    stremio
    dunst
    keepassxc
    xfce.thunar
    maim
    eddie # eddie has insecure packages, see permittedInsecurePackages in configuration.nix

    sysstat
    networkmanagerapplet
  ];

  programs.git = {
    enable = true;
    userName = "andersonjoseph";
    userEmail = "andersonjoseph@mailfence.com";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      cl = "clear";
      wtf = "sudo $(fc -ln -1)";
    };
  };

  programs.starship = {
    enable = true;
    settings = pkgs.lib.importTOML ./starship.toml;
  };

  home.file.".config/nvim".source = ./nvim;
}
