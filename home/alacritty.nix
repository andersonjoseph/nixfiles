{ ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
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
        # Vague theme colors
        primary = {
          background = "#141415";
          foreground = "#cdcdcd";
        };

        normal = {
          black = "#141415";
          red = "#d8647e";
          green = "#a8e6cf";
          yellow = "#f3be7c";
          blue = "#2c4a6e";
          magenta = "#bb9dbd";
          cyan = "#b4d4cf";
          white = "#cdcdcd";
        };

        bright = {
          black = "#4b4b4e";
          red = "#c48282";
          green = "#90a0b5";
          yellow = "#e0a363";
          blue = "#9bb4bc";
          magenta = "#aeaed1";
          cyan = "#c3c3d5";
          white = "#e8e8e8";
        };
      };
    };
  };
}
