{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.ashika = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
	./nordvpn.nix

	home-manager.nixosModules.home-manager ({config, ...}: {
	  home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;
	  home-manager.users.anderson = ./home.nix;
	  home-manager.backupFileExtension = "backup";

	  home-manager.extraSpecialArgs = {
	    inherit (config.networking) hostName;
	  };
	})
      ];
    };
  };
}
