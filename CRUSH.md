# Build Commands
sudo nixos-rebuild switch --flake .#{host}

# Lint/Format
nixfmt flake.nix options.nix home/default.nix hosts/*/default.nix hosts/*/hardware-configuration.nix
