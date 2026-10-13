{
  pkgs,
  config,
  ...
}:
let
  terminal-browser = pkgs.callPackage ../packages/terminal-browser.nix { };
in
{
  # `pkgs.herdr` comes from the herdr flake overlay applied in flake.nix.
  home.packages = [
    pkgs.herdr
    terminal-browser
  ];

  # Out-of-store symlink so live edits + `herdr server reload-config` apply
  # without a rebuild (same pattern as the nvim config).
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/herdr/config.toml";

  # The html-open plugin lives in the repo and stays live-editable; the
  # registry refreshes on every switch and linking works while herdr is
  # not running. Headless hosts are fine: terminal-browser renders
  # software-only into the terminal.
  home.activation.herdrHtmlOpenPlugin = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.herdr}/bin/herdr plugin unlink anderson.html-open >/dev/null 2>&1 || true
    $DRY_RUN_CMD ${pkgs.herdr}/bin/herdr plugin link \
      ${config.home.homeDirectory}/configuration/home/herdr/plugins/html-open
  '';
}
