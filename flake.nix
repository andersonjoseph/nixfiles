{
  description = "andersonjoseph NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nordvpn-flake.url = "path:./flakes/nordvpn";
    jailed-agents.url = "git+file:///home/anderson/projects/jailed-agents";
    herdr.url = "github:herdrdev/herdr";
    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nordvpn-flake, definitivo, herdr, hunk, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # Packages provided by flake inputs, exposed as pkgs.<name>.
      # ketch ships from the definitivo hub now, same pin as its skill.
      ketch-pkg = definitivo.packages.${system}.ketch;

      overlays = {
        nixpkgs.overlays = [
          herdr.overlays.default
          (_: _: {
            hunk = hunk.packages.${system}.hunk;
            ketch = ketch-pkg;
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

      jailed-opencode = jailed-agents.lib.${system}.makeJailedOpencode {
        enableNix = true;
        extraPkgs = [
          ketch-pkg
          pkgs.nodejs
        ];
        extraReadwriteDirs = [
          "~/.config/ketch"
          "~/.cache/ketch"
          "~/.local/share/opencode-jail"
        ];
        extraReadonlyDirs = [
          "~/configuration/home/opencode"
        ];
        env = {
          XDG_DATA_HOME = "/home/anderson/.local/share/opencode-jail";
        };
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
