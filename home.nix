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
    neovim
    vivaldi
    stremio
    keepassxc
    distrobox
    vlc

    xfce.thunar
    xfce.thunar-volman

    sysstat
    networkmanagerapplet
    dunst
    i3-auto-layout
    pavucontrol
    picom

    maim
    feh
    alsa-utils
    killall
    jq
    xclip
    bc
    fzf
    ripgrep
    tree
    ] ++ (lib.optionals (hostName == "ashika") [
	brightnessctl
    ]);

  programs.obs-studio = {
    enable = (hostName == "almazrah");
    package = (pkgs.obs-studio.override {
      cudaSupport = true;
    });
  };

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
