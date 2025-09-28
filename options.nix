{ lib, ... }:
{
  options.custom = {
    wallpaperFile = lib.mkOption {
      type = lib.types.path;
      default = null;
      description = ''
        	The absolute path to the wallpaper file for this host.
        	Nix will ensure this file exists and place it in the store
      '';
    };

    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system is a laptop or not";
    };

    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system is a desktop or not";
    };

    hasNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system has an Nvidia GPU or not";
    };

    xrandr = {
      startupCommand = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "specific xrandr command to run on startup. Useful for setting up a specific resolution";
      };
    };
  };
}
