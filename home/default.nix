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
            stremio
            keepassxc
            distrobox
            vlc
	    qbittorrent

            xfce.thunar
            xfce.thunar-volman
            xfce.thunar-archive-plugin

            autotiling
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
	    unzip
	    rofi
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

	programs.tmux = {
	  enable = true;
	  baseIndex = 1;
	  keyMode = "vi";
	  shortcut = "p";
	  plugins = with pkgs; [
	    tmuxPlugins.power-theme
	  ];
	  extraConfig = ''
	    set -sg escape-time 0
	    set -g status-interval 0
	    set -g default-terminal "tmux-256color"
	    set -ag terminal-overrides ",xterm-256color:RGB"
	  '';
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

        home.file.".config/picom.conf".source = ./picom.conf;
      };
  };
}
