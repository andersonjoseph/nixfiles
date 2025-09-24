# NixOS Configuration

This repository contains my personal NixOS configuration using Nix flakes and home-manager for managing system and user environments.

## Structure

- `flake.nix`: Main flake configuration defining inputs and outputs for each host.
- `home-manager.nix`: Home-manager module configuration.
- `home.nix`: User environment configuration (packages, programs, dotfiles).
- `hosts/`: Host-specific configurations.
  - `almazrah/`: Desktop configuration
  - `ashika/`: Laptop configuration
- `common/`: Shared modules and services.
- `i3/`: i3 window manager configuration.
- `nvim/`: Neovim configuration.
- Other files: Various dotfiles and scripts.
