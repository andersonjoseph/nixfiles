{ config, ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.anderson = import ./home.nix;
    extraSpecialArgs = {
      inherit (config.networking) hostName;
    };
  };
}
