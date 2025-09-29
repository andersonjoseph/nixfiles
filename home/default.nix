{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.anderson =
      {
        pkgs,
        lib,
        nixosConfig,
        ...
      }:
      {
        imports = [
          ./i3
          ./alacritty.nix
        ];

        home.stateVersion = "25.05";

        home.username = "anderson";
        home.homeDirectory = "/home/anderson";

        home.packages =
          with pkgs;
          [
            neovim
            vivaldi
            stremio
            keepassxc
            distrobox
            vlc

            xfce.thunar
            xfce.thunar-volman

            i3-auto-layout
            sysstat
            networkmanagerapplet
            dunst
            pavucontrol
            picom
            lxde.lxsession

            maim
            feh
            alsa-utils
            killall
            jq
            xclip
            bc
            fzf
            ripgrep
            tree
            (ffmpeg-full.override { withUnfree = true; })
          ]
          ++ (lib.optionals nixosConfig.custom.isLaptop [
            brightnessctl
          ]);

	services.redshift = {
	  enable = true;
	  dawnTime = "6:00-7:45";
	  duskTime = "18:35-20:15";
	  temperature = {
	    day = 6500;
	    night = 3500;
	  };
	};

        programs.obs-studio = lib.mkIf nixosConfig.custom.isDesktop {
          enable = true;
          package = (
            pkgs.obs-studio.override {
              cudaSupport = true;
            }
          );
        };

        programs.git = {
          enable = true;
          userName = "andersonjoseph";
          userEmail = "andersonjoseph@mailfence.com";

	  signing = {
	    signByDefault = true;
	    format = "ssh";
	  };
	};

        programs.bash = {
          enable = true;
          enableCompletion = true;
          shellAliases = {
            cl = "clear";
            wtf = "sudo $(fc -ln -1)";
          };
          initExtra = ''
            	  eval "$(fzf --bash)"
            	  '';
        };

        programs.starship = {
          enable = true;
          settings = pkgs.lib.importTOML ./starship.toml;
        };

        home.file."pictures/wallpaper" = lib.mkIf (nixosConfig.custom.wallpaperFile != null) {
          source = nixosConfig.custom.wallpaperFile;
        };

        home.file.".config/nvim".source = ./nvim;
        home.file.".config/picom.conf".source = ./picom.conf;
      };
  };
}
