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
        # Colors (Kanagawa-paper)
        primary = {
          background = "#1F1F28";
          foreground = "#DCD7BA";
        };

        normal = {
          black = "#16161D";
          red = "#C34043";
          green = "#76946A";
          yellow = "#DCA561";
          blue = "#7E9CD8";
          magenta = "#957FB8";
          cyan = "#6A9589";
          white = "#DCD7BA";
        };

        bright = {
          black = "#727169";
          red = "#FF5D62";
          green = "#98BB6C";
          yellow = "#FF9E3B";
          blue = "#7FB4CA";
          magenta = "#D27E99";
          cyan = "#7AA89F";
          white = "#DCD7BA";
        };
      };
    };
  };
}
