# NordVPN Flake

A standalone Nix flake for NordVPN client on NixOS. This flake provides the NordVPN CLI and GUI applications along with a complete NixOS module for managing NordVPN services.

## About

NordVPN offers a paid virtual private network (VPN) service. The service operates as closed-source, but the Linux client uses open-source code licensed under GPLv3.

## Packages

This flake provides the following packages:

- **libdrop** - NordVPN's filesharing library (Rust)
- **libtelio** - Library providing networking utilities for NordVPN (Rust)
- **nordvpn-cli** - CLI application containing client, daemon, and fileshare (Go)
- **nordvpn-gui** - Flutter-based GUI application
- **nordvpn** - Combined package (symlinkJoin of CLI + GUI)

## Quick Start

### Using with Flakes

Add the flake to your NixOS configuration:

```nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nordvpn.url = "path:/home/anderson/projects/nixpkgs/nordvpn-flake";
  };

  outputs = { self, nixpkgs, nordvpn, ... }: {
    nixosConfigurations.myHostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        nordvpn.nixosModules.nordvpn
      ];
    };
  };
}
```

### Minimal Configuration

Add this to your `configuration.nix`:

```nix
{
  # Enable NordVPN service
  services.nordvpn.enable = true;

  # Firewall configuration
  networking.firewall.enable = true;
  networking.firewall.checkReversePath = "loose";

  # Add your user to nordvpn group
  users.users.yourUser = {
    isNormalUser = true;
    extraGroups = [ "wheel" "nordvpn" ];
  };
}
```

### Apply Configuration

```bash
sudo nixos-rebuild switch
```

## Configuration Options

### Basic Options

- `services.nordvpn.enable` - Enable NordVPN (default: `false`)
- `services.nordvpn.user` - User under which `nordvpnd` is run (default: `"nordvpn"`)
- `services.nordvpn.group` - Group under which `nordvpnd` is run (default: `"nordvpn"`)

### Advanced Configuration

If you prefer to use your own user and group:

```nix
{
  services.nordvpn = {
    enable = true;
    user = "myuser";
    group = "mygroup";
  };

  users.users.myuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" "mygroup" ];
  };
}
```

## Using NordVPN

### CLI Commands

After enabling the service, you can use the following CLI commands:

```bash
# Log in using an OAuth URL
nordvpn login

# Log in with a token obtained from your NordVPN account
nordvpn login --token <token>

# Connect to VPN
nordvpn c

# Connect to a NordVPN server in Ireland
nordvpn c ie

# Disconnect from VPN
nordvpn d

# Switch to OpenVPN technology
nordvpn set technology openvpn

# Reconnect after changing technology
nordvpn c

# View current status
nordvpn status

# List available countries
nordvpn countries

# List available servers in a country
nordvpn cities ie

# Set auto-connect on boot
nordvpn set autoconnect on

# Enable kill-switch
nordvpn set killswitch on

# View settings
nordvpn settings
```

### Using the GUI

If you prefer a friendly GUI:

```bash
nordvpn-gui
```

The GUI provides a graphical interface to:
- Connect/disconnect from VPN servers
- View server locations
- Manage settings
- Access file sharing features

## Services

The module automatically manages the following systemd services:

### System Services

- **systemd.service.nordvpnd** - Main NordVPN daemon
  - Requires `CAP_NET_ADMIN` capability
  - Manages VPN connections
  - Runs as the configured user/group

- **systemd.socket.nordvpnd** - Socket activation for the daemon
  - Listens on `/run/nordvpn/nordvpnd.sock`

### User Services

- **systemd.user.service.norduserd** - NordVPN user daemon
  - Runs in user session
  - Manages user-specific features
  - Enabled automatically for graphical sessions

- **systemd.user.service.nordvpn-fileshare** - NordVPN file share service
  - Provides file sharing over meshnet
  - Depends on norduserd
  - Enabled automatically for graphical sessions

### Dependencies

The module automatically enables:

- **services.resolved** - systemd-resolved for DNS configuration
- **security.polkit** - PolicyKit for DNS management permissions

## Firewall Configuration

When using a firewall, you must set `networking.firewall.checkReversePath` to `"loose"` or `false`:

```nix
{
  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
  };
}
```

NordVPN includes a `kill-switch` feature that blocks all packets not associated with the VPN connection. This works best with relaxed reverse path filtering.

## Troubleshooting

### Connection Issues

1. **Check service status:**
   ```bash
   sudo systemctl status nordvpnd
   ```

2. **Check daemon logs:**
   ```bash
   sudo journalctl -u nordvpnd -f
   ```

3. **Verify user group membership:**
   ```bash
   groups your-user
   ```
   Ensure `nordvpn` (or your custom group) is in the list.

### Permission Issues

If you encounter permission errors:

1. Ensure your user is in the nordvpn group:
   ```bash
   sudo usermod -aG nordvpn your-user
   ```

2. Re-login or restart your session for group changes to take effect.

3. Check polkit is running:
   ```bash
   sudo systemctl status polkit
   ```

### DNS Issues

If DNS resolution fails after connecting:

1. Check systemd-resolved status:
   ```bash
   sudo systemctl status systemd-resolved
   ```

2. View resolved logs:
   ```bash
   sudo journalctl -u systemd-resolved -f
   ```

### GUI Not Launching

If the GUI doesn't start:

1. Ensure you're in a graphical session
2. Check norduserd status:
   ```bash
   systemctl --user status norduserd
   ```
3. Check GUI logs:
   ```bash
   journalctl --user -u nordvpn-gui
   ```

## Running Without Module

If you want to use the packages without the NixOS module:

```nix
{
  environment.systemPackages = [
    inputs.nordvpn.packages.x86_64-linux.nordvpn
  ];
}
```

You'll need to manually manage the daemons and configuration.

## Development

### Building Packages

Build all packages:

```bash
nix build .#
```

Build specific package:

```bash
nix build .#nordvpn-cli
nix build .#nordvpn-gui
nix build .#libdrop
nix build .#libtelio
```

### Using Apps

Run CLI:

```bash
nix run .#nordvpn-cli
```

Run GUI:

```bash
nix run .#nordvpn-gui
```

## Architecture

The NordVPN package consists of:

1. **libdrop** - Rust library for file sharing
2. **libtelio** - Rust library for networking utilities
3. **nordvpn-cli** - Go application with:
   - `nordvpn` - CLI client
   - `nordvpnd` - System daemon
   - `nordfileshare` - File share daemon
   - `norduserd` - User daemon
4. **nordvpn-gui** - Flutter-based GUI application
5. **nordvpn** - SymlinkJoin of CLI and GUI packages

## Known Limitations

- Meshnet is currently not supported on NixOS
- Some features may require additional manual configuration
- The module is self-contained and doesn't support custom package overrides

## Contributing

Contributions are welcome! This is a standalone flake extracted from the nixpkgs repository's `nordvpn-meshnet` branch.

## License

- Linux client: GPLv3
- libdrop: GPLv3
- libtelio: GPLv3
- GUI: See upstream repository

## Upstream

- NordVPN Linux: https://github.com/NordSecurity/nordvpn-linux
- libdrop: https://github.com/NordSecurity/libdrop
- libtelio: https://github.com/NordSecurity/libtelio

## Disclaimer

**NixOS currently does not support meshnet.**

Contributions welcome!
