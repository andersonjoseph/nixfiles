{
  description = "andersonjoseph NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nordvpn-flake.url = "path:./flakes/nordvpn";
    jailed-agents.url = "github:andersonjoseph/jailed-agents";
    jailed-agents.inputs.llm-agents.follows = "llm-agents";
    llm-agents.url = "github:numtide/llm-agents.nix/04f4e45f5be619f430cb5be5c0f579b8ecb27324";
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
    { nixpkgs, home-manager, nordvpn-flake, jailed-agents, llm-agents, hunk, sideshow, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # Packages provided by flake inputs, exposed as pkgs.<name>.
      sideshow-pkg = pkgs.callPackage ./packages/sideshow.nix { sideshow-src = sideshow; };
      t3-server = pkgs.callPackage ./packages/t3code/package.nix { };

      overlays = {
        nixpkgs.overlays = [
          (_: _: {
            hunk = hunk.packages.${system}.hunk;
            sideshow = sideshow-pkg;
            pi = free-pi;
            claude-code = free-claude-code;
            inherit
              jailed-pi
              jailed-claude-code
              t3-server
              ;
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

      jailed-pi = jailed-agents.lib.${system}.makeJailedPi {
        name = "jailed-pi";
        enableNix = true;
        extraPkgs = [
          sideshow-pkg
        ];
      };

      jailed-claude-code = jailed-agents.lib.${system}.makeJailedClaudeCode {
        name = "jailed-claude-code";
        enableNix = true;
        extraPkgs = [
          sideshow-pkg
          pkgs.nodejs
        ];
      };

      free-pi = llm-agents.packages.${system}.pi;
      free-claude-code = llm-agents.packages.${system}.claude-code;
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
