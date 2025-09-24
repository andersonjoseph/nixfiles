{ config, pkgs, lib, hostName, ... }:

# All configuration attributes are now nested under 'config'
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

    sysstat
    networkmanagerapplet
    i3-auto-layout
    feh
    picom
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
    initExtra = ''
      eval "$(fzf --bash)"
    '';
  };

  programs.starship = {
    enable = true;
    settings = pkgs.lib.importTOML ./starship.toml;
  };

  home.file."pictures/wallpaper".source = ./hosts/${hostName}/wallpaper;
  home.file.".config/nvim".source = ./nvim;
  home.file.".config/picom.conf".source = ./picom.conf;
}
