{
  description = "NordVPN client for NixOS - standalone flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        lib = pkgs.lib;
        version = "4.5.0";
        commonArgs = {
          myVersion = version;

          mySrc = pkgs.fetchgit {
            url = "https://github.com/NordSecurity/nordvpn-linux.git";
            rev = "refs/tags/${version}";
            fetchSubmodules = false;
            hash = "sha256-nxRKYKR4ZPBAhveyG2I5ZmbftYr4hliEcRaZdjd4Sj0=";
          };

          myMeta = rec {
            homepage = "https://github.com/nordsecurity/nordvpn-linux";
            changelog = "${homepage}/blob/main/contrib/changelog/prod/${version}.md";
            license = lib.licenses.gpl3Only;
            maintainers = with lib.maintainers; [ different-error ];
            platforms = lib.platforms.linux;
          };

          myDesktopItemArgs = {
            categories = [ "Network" ];
            genericName = "a vpn provider";
            icon = "nordvpn";
            type = "Application";
          };
        };
      in {
        packages = {
          # libdrop - NordVPN's filesharing library
          libdrop = pkgs.callPackage ./packages/libdrop/package.nix {};

          # libtelio - Library providing networking utilities for NordVPN
          libtelio = pkgs.callPackage ./packages/libtelio/package.nix {};

          # nordvpn-cli - CLI application (contains client, daemon, and fileshare)
          nordvpn-cli = pkgs.callPackage ./packages/nordvpn/cli.nix (
            commonArgs // {
              inherit (config.packages) libdrop libtelio;
            }
          );

          # nordvpn-gui - Flutter GUI application
          nordvpn-gui = pkgs.callPackage ./packages/nordvpn/gui.nix commonArgs;

          # nordvpn - Combined package (CLI + GUI)
          nordvpn = pkgs.callPackage ./packages/nordvpn/package.nix {
            inherit (config.packages) nordvpn-cli nordvpn-gui;
          };

          default = config.packages.nordvpn;
        };

        # Apps for convenient running
        apps = {
          nordvpn-cli = {
            type = "app";
            program = lib.getExe config.packages.nordvpn-cli;
          };
          nordvpn-gui = {
            type = "app";
            program = lib.getExe config.packages.nordvpn-gui;
          };
        };
      };

      flake = {
        # NixOS module
        nixosModules.nordvpn = {
          config,
          lib,
          pkgs,
          ...
        }: let
          version = "4.5.0";
          commonArgs = {
            myVersion = version;

            mySrc = pkgs.fetchgit {
              url = "https://github.com/NordSecurity/nordvpn-linux.git";
              rev = "refs/tags/${version}";
              fetchSubmodules = false;
              hash = "sha256-nxRKYKR4ZPBAhveyG2I5ZmbftYr4hliEcRaZdjd4Sj0=";
            };

            myMeta = rec {
              homepage = "https://github.com/nordsecurity/nordvpn-linux";
              changelog = "${homepage}/blob/main/contrib/changelog/prod/${version}.md";
              license = lib.licenses.gpl3Only;
              maintainers = with lib.maintainers; [ different-error ];
              platforms = lib.platforms.linux;
            };

            myDesktopItemArgs = {
              categories = [ "Network" ];
              genericName = "a vpn provider";
              icon = "nordvpn";
              type = "Application";
            };
          };

          nordvpn-cli = pkgs.callPackage ./packages/nordvpn/cli.nix (commonArgs // {
            libdrop = pkgs.callPackage ./packages/libdrop/package.nix {};
            libtelio = pkgs.callPackage ./packages/libtelio/package.nix {};
          });

          nordvpn-gui = pkgs.callPackage ./packages/nordvpn/gui.nix commonArgs;
        in
          import ./module/nordvpn {
            inherit config lib pkgs;
            nordvpn-cli = nordvpn-cli;
            nordvpn-gui = nordvpn-gui;
          };
      };
    };
}
