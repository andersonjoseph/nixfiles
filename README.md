# NixOS Configuration

Personal NixOS configuration managed with Nix flakes and home-manager. It defines
multiple hosts that share a common base, plus a home-manager user environment.

## Prerequisites

- Nix >=2.22 with flakes enabled
- x86_64-linux

## Applying a configuration

Build and switch a host (run on the target machine):

```sh
sudo nixos-rebuild switch --flake .#<host>
# e.g. sudo nixos-rebuild switch --flake .#ashika
```

The available hosts are: `ashika`, `lyndon`, `vondel`.

## Structure

- `flake.nix` — Flake inputs and outputs. Defines four `nixosConfigurations`
  (`ashika`, `lyndon`, `vondel`), each composed from its host module,
  `./home`, home-manager, and a shared `nordvpn-module`. Also exposes a
  `devShells` output.
- `options.nix` — Custom `custom.*` options consumed by hosts and home-manager:
  `wallpaperFile`, `hasNvidia`, `isGaming`, `xrandr.startupCommand`.
- `hosts/` — Host-specific configurations; each imports `../common`.
  - `common/` — Shared base system config (docker, networkmanager, locale,
    fonts, X/i3, bluetooth, swap, nix gc) used by every host. Also installs
    `hosts/common/vondel.crt` so the `vondel` server's internal TLS cert is
    trusted everywhere.
  - `ashika/` — Laptop (Intel graphics, battery tuning, gaming enabled).
  - `lyndon/` — Laptop (hybrid NVIDIA/Intel PRIME offload, external monitor via
    xrandr, battery tuning, Thunderbolt).
  - `vondel/` — Headless server (Caddy reverse proxy with internal TLS, Open
    WebUI, Eternal Terminal, Docker, firewall).
- `home/` — home-manager user environment (`home/default.nix`).
  - `alacritty.nix`, `starship.toml`, `herdr/` — terminal, prompt, and
    multiplexer config.
  - `i3/` — i3 window manager and bar setup.
  - `nvim/` — Neovim config (LSP, plugins), symlinked into `~/.config/nvim`.
  - `pi/` — `pi` agent config (`AGENTS.md`, `skills/`, `extensions/`,
    `prompts/`), symlinked into `~/.pi/agent` via a home-manager activation
    script.
- `flakes/nordvpn/` — Vendored standalone flake providing the NordVPN CLI/GUI
  packages and a NixOS module; consumed by `flake.nix` as `nordvpn-flake`.
- `scripts/` — Utility scripts (e.g., `change-audio-port`).
