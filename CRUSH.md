# Build Commands
sudo nixos-rebuild switch --flake .#{host}
home-manager switch --flake .#{host}

# Lint/Format
nixfmt flake.nix options.nix home/default.nix hosts/*/default.nix hosts/*/hardware-configuration.nix