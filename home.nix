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
        "window_type = 'desktop'"
        "class_g = 'i3-frame'"
        "class_g = 'i3-workspace'"
        "class_g = 'i3-gap'"
        "class_g = 'i3-dock'"
        "class_g = 'dunst'"
        "class_g = 'Conky'"
        "class_g = 'rofi'"
        "class_g = 'waybar'"
        "class_g = 'firefox'"
      ];

      inactive-opacity-override = false;
      inactive-dim = 0.2;
    };
  };

  home.file.".config/nvim".source = ./nvim;
}
