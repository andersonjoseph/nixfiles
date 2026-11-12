{
  pkgs,
  lib,
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

  # herdr canonicalizes the plugin root at link time, so a symlink into the
  # store would pin a path that dies with the next rebuild. Materialize the
  # manifest and binary as real files at a stable path instead.
  home.activation.herdrOcworktrees = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run rm -rf "$HOME/.local/share/herdr-ocworktrees"
    run install -d "$HOME/.local/share/herdr-ocworktrees"
    run install -m755 "${pkgs.herdr-ocworktrees}/share/herdr-ocworktrees/herdr-ocworktrees" "$HOME/.local/share/herdr-ocworktrees/herdr-ocworktrees"
    run install -m644 "${pkgs.herdr-ocworktrees}/share/herdr-ocworktrees/herdr-plugin.toml" "$HOME/.local/share/herdr-ocworktrees/herdr-plugin.toml"
  '';

  home.file.".config/herdr/plugins/config/andersonjoseph.ocworktrees/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/herdr/ocworktrees-config.toml";
}
