{
  description = "andersonjoseph NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nordvpn-pr.url = "path:/home/anderson/projects/nixpkgs";


    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nordvpn-pr, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixd
          nixfmt-rfc-style
        ];
      };

      nixosConfigurations.ashika = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/ashika
          ./home
          home-manager.nixosModules.home-manager
        ];
      };

      nixosConfigurations.almazrah = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	  (
	   {...}: {
	     imports = [
	       "${nordvpn-pr}/nixos/modules/services/networking/nordvpn.nix"
	     ];

	     documentation.nixos.enable = false;
	     environment.etc.hosts.mode = "0666";

	     nixpkgs.overlays = [
	      (self: super: {
		nordvpn = nordvpn-pr.legacyPackages.${system}.nordvpn;
	      })
	     ];

	     services.nordvpn = {
	       enable = true;
	     };
	     networking.firewall.enable = false;
	   }
	  )

          ./hosts/almazrah
          ./home
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
