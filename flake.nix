{
  description = "andersonjoseph NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nordvpn-flake.url = "path:./flakes/nordvpn";
    ketch.url = "github:1broseidon/ketch/v0.18.1";
    ketch.flake = false;
    jailed-agents.url = "github:andersonjoseph/jailed-agents";
    herdr.url = "github:herdrdev/herdr";
    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nordvpn-flake, jailed-agents, herdr, hunk, ketch, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # Packages provided by flake inputs, exposed as pkgs.<name>.
      ketch-pkg = pkgs.callPackage ./packages/ketch.nix { ketch-src = ketch; };
      commit-walkthrough-pkg = pkgs.callPackage ./packages/commit-walkthrough.nix { };

      overlays = {
        nixpkgs.overlays = [
          herdr.overlays.default
          (_: _: {
            hunk = hunk.packages.${system}.hunk;
            ketch = ketch-pkg;
            commit-walkthrough = commit-walkthrough-pkg;
            inherit jailed-opencode;
          })
        ];
      };
      nordvpn-module = ({...}: {
	  imports = [
	    nordvpn-flake.nixosModules.nordvpn
	  ];
	  services.nordvpn.enable = true;
	  environment.etc.hosts.mode = "0666";
	  networking.firewall = {
	    enable =  true;
	    checkReversePath = "loose";
	};
      });

      jailed-opencode = jailed-agents.lib.${system}.makeJailedOpencode2 {
        enableNix = true;
        extraPkgs = [
          ketch-pkg
          commit-walkthrough-pkg
          pkgs.nodejs
        ];
        extraReadwriteDirs = [
          "~/.config/ketch"
          "~/.cache/ketch"
        ];
        extraReadonlyDirs = [
          "~/configuration/home/opencode"
        ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixd
          nixfmt-rfc-style
        ];
      };

      packages.${system}.commit-walkthrough = commit-walkthrough-pkg;

      nixosConfigurations.vondel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
	modules = [
	  overlays
	  nordvpn-module
	  ./hosts/vondel
	  ./home
	  home-manager.nixosModules.home-manager
	];
      };

      nixosConfigurations.ashika = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	  overlays
	  nordvpn-module
          ./hosts/ashika
          ./home
          home-manager.nixosModules.home-manager
        ];
      };

      nixosConfigurations.lyndon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	  overlays
	  nordvpn-module
          ./hosts/lyndon
          ./home
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
