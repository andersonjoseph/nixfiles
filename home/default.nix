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
	config,
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
            keepassxc
            vlc
	    qbittorrent
	    jamesdsp
	    xarchiver
	    darktable
	    cherry-studio

            xfce.thunar
            xfce.thunar-volman
            xfce.thunar-archive-plugin
	    xfce.xfconf

            autotiling
            sysstat
            networkmanagerapplet
            dunst
            pavucontrol
            lxsession

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
	    unzip
	    rofi
	    lsof
            (ffmpeg-full.override { withUnfree = true; })
          ]
          ++ (lib.optionals nixosConfig.custom.isLaptop [
            brightnessctl
          ]);

	services.redshift = {
	  enable = true;
	  dawnTime = "7:00";
	  duskTime = "16:35";
	  temperature = {
	    day = 6500;
	    night = 3500;
	  };
	};

	programs.ssh = {
	  enable = true;
	  enableDefaultConfig = false; 
	  matchBlocks = {
	    "*" = {
	      forwardAgent = false;
	      hashKnownHosts = true;
	      addKeysToAgent = "yes";
	    };
	    "github.com" = {
	      identityFile = "~/.ssh/identity/anderson";
	    };
	    "vondel-nord" = {
	      user = "anderson";
	      identityFile = "~/.ssh/access/vondel";
	    };
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
	  settings = {
	    user = {
	      name = "anderson";
	      email = "andersonjoseph@mailfence.com";
	    };
	  };
	  signing = {
	    signByDefault = true;
	    format = "ssh";
	  };
	};

	programs.lazygit = {
	  enable = true;
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
	  bashrcExtra = ''
	    export MANPAGER='nvim +Man!'
	    export PATH="$PATH:$HOME/go/bin"
	  '';
        };

	programs.direnv = {
	  enable = true;
	  enableBashIntegration = true;
	  nix-direnv.enable = true;
	};

        programs.starship = {
          enable = true;
          settings = pkgs.lib.importTOML ./starship.toml;
        };

        home.file."pictures/wallpaper" = lib.mkIf (nixosConfig.custom.wallpaperFile != null) {
          source = nixosConfig.custom.wallpaperFile;
        };

	home.file.".config/nvim" = {
	  source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/nvim";
	};
      };
  };
}
