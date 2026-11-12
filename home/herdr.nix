{
  pkgs,
  config,
  ...
}:
{
  # `pkgs.herdr` comes from the herdr flake overlay applied in flake.nix.
  home.packages = [ pkgs.herdr ];

  # Out-of-store symlink so live edits + `herdr server reload-config` apply
  # without a rebuild (same pattern as the nvim config).
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/herdr/config.toml";

  # Stable plugin root for `herdr plugin link ~/.local/share/herdr-ocworktrees`
  # (one-time, per machine; herdr owns its plugins.json registry).
  home.file.".local/share/herdr-ocworktrees".source =
    "${pkgs.herdr-ocworktrees}/share/herdr-ocworktrees";

  home.file.".config/herdr/plugins/config/andersonjoseph.ocworktrees/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/herdr/ocworktrees-config.toml";
}
