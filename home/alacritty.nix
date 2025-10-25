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
          family = "TX\-02 Retina Semicondensed";
        };
        size = 11;
      };

      colors = {
        # Colors (Kanso Ink theme)
        primary = {
          background = "#14171d";
          foreground = "#C5C9C7";
        };

        normal = {
          black = "#090E13";
          red = "#C34043";
          green = "#98BB6C";
          yellow = "#DCA561";
          blue = "#7FB4CA";
          magenta = "#938AA9";
          cyan = "#8ea4a2";
          white = "#f2f1ef";
        };

        bright = {
          black = "#717C7C";
          red = "#E46876";
          green = "#87a987";
          yellow = "#E6C384";
          blue = "#658594";
          magenta = "#8992a7";
          cyan = "#8ba4b0";
          white = "#C5C9C7";
        };
      };
    };
  };
}
