# NixOS Configuration

This repository contains my personal NixOS configuration using Nix flakes and home-manager for managing system and user environments.

## Prerequisites

- Nix >=2.22 with flakes enabled
- Supported on x86_64-linux

## Structure

- `flake.nix`: Main flake configuration defining inputs and outputs for each host.
- `options.nix`: Custom NixOS options for host-specific settings (wallpaper, hardware flags).
- `home/default.nix`: User environment configuration (packages, programs, dotfiles) via home-manager.
- `hosts/`: Host-specific configurations.
  - `almazrah/`: Desktop configuration (NVIDIA GPU, external drive).
  - `ashika/`: Laptop configuration (Intel graphics, battery optimizations).
  - `common/`: Shared modules (e.g., NordVPN).
- `home/`: Home-manager modules.
  - `alacritty.nix`, `starship.toml`, `picom.conf`: Dotfile configurations.
  - `i3/`: i3 window manager and bar setup.
  - `nvim/`: Neovim configuration with LSP, plugins, and settings.
- `scripts/`: Utility scripts.
- Other files: Various dotfiles and Nix expressions.

