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
      modules = [
        ./hosts/ashika
	./home-manager.nix
	home-manager.nixosModules.home-manager  
      ];
    };

    nixosConfigurations.almazrah = nixpkgs.lib.nixosSystem {
      modules = [
        ./hosts/almazrah
	./home-manager.nix
	home-manager.nixosModules.home-manager  
      ];
    };
  };
}
