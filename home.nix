{ config, pkgs, lib, ... }:

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
    eddie # eddie has insecure packages, see permittedInsecurePackages in configuration.nix

    sysstat
    networkmanagerapplet
    i3-auto-layout
    feh
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

  services.picom = {
    enable = true;
    backend = "glx";
    vSync = false;

    activeOpacity = 0.9;
    inactiveOpacity = 0.8;
    opacityRules = [
      "100:class_i = 'vivaldi-stable'"
      "100:class_g = 'Vivaldi-stable'"
      "90:name = 'browser_popup'"
      "100:class_i = 'stremio'"
      "100:class_g = 'Stremio'"
      "100:class_g = 'darktable'"
      "100:class_g = 'Darktable'"
      "100:class_g = 'vlc'"
    ];

    settings = {
      round-borders = 1;
      corner-radius = 10;
      detect-rounded-corners = true;
      rounded-corners-exclude = [
	"class_g = 'i3bar'"
	"class_i = 'i3bar'"
	"class_i = 'dmenu'"
	"class_g = 'dmenu'"
      ];

      blur = {
	method = "dual_kawase";
	strength = 4;
      };
      blur-background-exclude = [
	"window_type = 'dock'"
	"class_g = 'Vivaldi'"
	"override_redirect = true"
	"class_g = 'Stremio'"
	"class_i = 'stremio'"
	"class_g = 'darktable'"
	"class_g = 'Darktable'"
	"class_g = 'vlc'"
      ];
      inactive-opacity-override = false;
      inactive-dim = 0.2;
    };
  };

  home.file."pictures/wallpaper".source = ./wallpaper;

  home.file.".config/nvim".source = ./nvim;
}
