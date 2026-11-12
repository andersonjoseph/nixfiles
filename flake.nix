{
  description = "andersonjoseph NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nordvpn-flake.url = "path:./flakes/nordvpn";
    llm-agents.url = "github:numtide/llm-agents.nix/78f777ba4f6141fca604a5cee3f6ff8dfab09f48";
    jailed-agents.url = "github:andersonjoseph/jailed-agents";
    jailed-agents.inputs.llm-agents.follows = "llm-agents";
    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";
    hex.url = "github:anomalyco/hex";
    herdr.url = "github:herdrdev/herdr";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nordvpn-flake,
      jailed-agents,
      llm-agents,
      hex,
      hunk,
      herdr,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      plannotator-pkg = pkgs.callPackage ./packages/plannotator.nix { };
      herdr-ocworktrees-pkg = pkgs.callPackage ./packages/herdr-ocworktrees.nix { };

      overlays = {
        nixpkgs.overlays = [
          herdr.overlays.default
          (_: _: {
            hunk = hunk.packages.${system}.hunk;
            hex = hex.packages.${system}.default.overrideAttrs { doCheck = false; };
            plannotator = plannotator-pkg;
            herdr-ocworktrees = herdr-ocworktrees-pkg;
            opencode2 = llm-agents.packages.${system}.opencode2;
            inherit jailed-opencode2;
          })
        ];
        home-manager.sharedModules = [ hex.homeManagerModules.hex ];
      };
      nordvpn-module = (
        { ... }: {
          imports = [
            nordvpn-flake.nixosModules.nordvpn
          ];
          services.nordvpn.enable = true;
          # nordvpnd runs as its own system user and rewrites /etc/hosts on
          # connect, so the file must stay writable by it.
          environment.etc.hosts.mode = "0666";
          networking.firewall = {
            enable = true;
            # tunnel reply traffic arrives on the nordlynx interface; strict
            # reverse-path filtering would drop it as spoofed.
            checkReversePath = "loose";
          };
        }
      );

      jailed-opencode2 = jailed-agents.lib.${system}.makeJailedOpencode2 {
        enableNix = true;
        enableOpenUrls = true;
        enableClaudeCode = true;
        extraReadwriteDirs = [
          "~/configuration"
          "/tmp"
          "~/.plannotator"
          "~/.cache/opencode"
        ];
        extraPkgs = [ plannotator-pkg ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixd
          nixfmt-rfc-style
        ];
      };

      packages.${system} = {
        plannotator = plannotator-pkg;
        herdr-ocworktrees = herdr-ocworktrees-pkg;
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
