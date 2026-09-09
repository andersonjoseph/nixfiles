{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "TX-02";
      font-size = 15;

      # Jellybeans (muted), same palette as alacritty/i3
      background = "#101010";
      foreground = "#dad6c8";
      palette = [
        "0=#101010"
        "1=#cc4d4d"
        "2=#98b67c"
        "3=#d9a45a"
        "4=#7db7cc"
        "5=#b8aed3"
        "6=#617b87"
        "7=#bebebe"
        "8=#3c3b38"
        "9=#cc4d4d"
        "10=#6aa84c"
        "11=#d8a16c"
        "12=#a6c3d9"
        "13=#b8aed3"
        "14=#a5acb1"
        "15=#dad6c8"
      ];

      # No title bar, i3 owns window chrome
      gtk-titlebar = false;

      # Same as alacritty so ssh'ed hosts don't need ghostty terminfo
      term = "xterm-256color";
    };
  };
}
