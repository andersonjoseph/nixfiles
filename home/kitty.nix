{ ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "TX-02";
      font_size = "15";

      # Jellybeans (muted), same palette as alacritty/i3
      background = "#101010";
      foreground = "#dad6c8";
      color0 = "#101010";
      color1 = "#cc4d4d";
      color2 = "#98b67c";
      color3 = "#d9a45a";
      color4 = "#7db7cc";
      color5 = "#b8aed3";
      color6 = "#617b87";
      color7 = "#bebebe";
      color8 = "#3c3b38";
      color9 = "#cc4d4d";
      color10 = "#6aa84c";
      color11 = "#d8a16c";
      color12 = "#a6c3d9";
      color13 = "#b8aed3";
      color14 = "#a5acb1";
      color15 = "#dad6c8";

      # No title bar, i3 owns window chrome
      hide_window_decorations = "yes";

      # Crisper text than the default 1.0 0 without looking bold
      text_composition_strategy = "0.5 5";

      # Same as alacritty so ssh'ed hosts don't need kitty terminfo
      term = "xterm-256color";
    };

    # Ghostty-style font zoom (kitty default is ctrl+shift)
    keybindings = {
      "ctrl+equal" = "change_font_size all +2.0";
      "ctrl+minus" = "change_font_size all -2.0";
      "ctrl+0" = "change_font_size all 0";
    };
  };
}
