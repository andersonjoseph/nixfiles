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
  }: let
    commonArgsFor = {
      lib,
      pkgs,
    }: let
      version = "5.2.0";
    in {
      myVersion = version;

      mySrc = pkgs.fetchFromGitHub {
        owner = "nordsecurity";
        repo = "nordvpn-linux";
        rev = "c4ba2feabad5cd1396ebc7e337cacb29027e6c01"; # 5.2.0
        hash = "sha256-F7iw856HVLbOz97j9sMkVwyZl0ZDwID1Tf0YwtdvZsU=";
      };

      myMeta = rec {
        homepage = "https://github.com/nordsecurity/nordvpn-linux";
        changelog = "${homepage}/releases/tag/${version}";
        license = lib.licenses.gpl3Only;
        maintainers = with lib.maintainers; [ different-error ];
        platforms = lib.platforms.linux;
      };

      myDesktopItemArgs = {
        categories = ["Network"];
        genericName = "VPN Client";
        icon = "nordvpn";
        type = "Application";
      };
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        lib = pkgs.lib;
        commonArgs = commonArgsFor {inherit lib pkgs;};
      in {
        packages = {
          libdrop = pkgs.callPackage ./packages/libdrop/package.nix {};

          libtelio = pkgs.callPackage ./packages/libtelio/package.nix {};

          nordvpn-cli = pkgs.callPackage ./packages/nordvpn/cli.nix (
            commonArgs
            // {
              inherit (config.packages) libdrop libtelio;
            }
          );

          nordvpn-gui = pkgs.callPackage ./packages/nordvpn/gui.nix commonArgs;

          nordvpn = pkgs.callPackage ./packages/nordvpn/package.nix {
            inherit (config.packages) nordvpn-cli nordvpn-gui;
          };

          default = config.packages.nordvpn;
        };

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
        nixosModules.nordvpn = {
          config,
          lib,
          pkgs,
          ...
        }: let
          commonArgs = commonArgsFor {inherit lib pkgs;};
          nordvpn-cli = pkgs.callPackage ./packages/nordvpn/cli.nix (commonArgs
            // {
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
