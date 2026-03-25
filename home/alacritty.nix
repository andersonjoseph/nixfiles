{ pkgs, ... }:
let
  notificationSound = ./alacritty-notification.mp3;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      bell = {
	command = {
	  program = "${pkgs.bash}/bin/sh";
	  args = [
	    "-c"
	    "${pkgs.dunst}/bin/dunstify alacritty 'Terminal needs your attention!' & ${pkgs.pulseaudio}/bin/paplay ${notificationSound}"
	  ];
	};
      };
      env = {
        "TERM" = "xterm-256color";
      };

      font = {
        normal = {
          family = "TX-02";
        };
        size = 11;
      };

      colors = {
        # Jellybeans (muted)
        primary = {
          background = "#101010";
          foreground = "#dad6c8";
        };

        normal = {
          black = "#101010";
          red = "#cc4d4d";
          green = "#98b67c";
          yellow = "#d9a45a";
          blue = "#7db7cc";
          magenta = "#b8aed3";
          cyan = "#617b87";
          white = "#bebebe";
        };

        bright = {
          black = "#3c3b38";
          red = "#cc4d4d";
          green = "#6aa84c";
          yellow = "#d8a16c";
          blue = "#a6c3d9";
          magenta = "#b8aed3";
          cyan = "#a5acb1";
          white = "#dad6c8";
        };
      };
      keyboard.bindings = [
	{
	  key = "f";
	  mods = "Control|Shift";
	  action = "ReceiveChar";
	}
      ];
    };
  };
}
