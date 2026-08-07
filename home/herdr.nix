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
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/configuration/home/herdr/config.toml";
}
