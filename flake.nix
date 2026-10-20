{
  description = "andersonjoseph NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nordvpn-flake.url = "path:./flakes/nordvpn";
    jailed-agents.url = "github:andersonjoseph/jailed-agents";
    herdr.url = "github:herdrdev/herdr";
    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";
    sideshow.url = "github:modem-dev/sideshow";
    sideshow.flake = false;

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nordvpn-flake, jailed-agents, herdr, hunk, sideshow, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # Packages provided by flake inputs, exposed as pkgs.<name>.
      sideshow-pkg = pkgs.callPackage ./packages/sideshow.nix { sideshow-src = sideshow; };
      t3-server = pkgs.callPackage ./packages/t3code/package.nix { };

      overlays = {
        nixpkgs.overlays = [
          herdr.overlays.default
          (_: _: {
            hunk = hunk.packages.${system}.hunk;
            sideshow = sideshow-pkg;
            inherit jailed-opencode t3-server;
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
          sideshow-pkg
          pkgs.nodejs
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
