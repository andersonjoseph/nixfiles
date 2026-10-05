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
      let
        isDesktopMachine = builtins.elem nixosConfig.networking.hostName [ "ashika" "lyndon" ];
      in
      {
        imports =
          [
            ./herdr.nix
          ]
          ++ (lib.optionals isDesktopMachine [
            ./i3
            ./alacritty.nix
            ./kitty.nix
          ]);

        home.stateVersion = "25.05";

        home.username = "anderson";
        home.homeDirectory = "/home/anderson";

        home.packages =
          with pkgs;
          [
            neovim
            hunk
            ketch
            jailed-pi
            jq
            ripgrep
            tree
            fzf
            killall
            unzip
            lsof
            bc
          ]
          ++ (lib.optionals isDesktopMachine [
            vivaldi
            google-chrome
            keepassxc
            vlc
            qbittorrent
            jamesdsp
            xarchiver
            darktable
            slack
            thunderbird

            thunar
            thunar-volman
            thunar-archive-plugin
            xfconf

            autotiling
            sysstat
            networkmanagerapplet
            dunst
            pavucontrol
            lxsession

            maim
            feh
            alsa-utils
            xclip
            rofi
            (ffmpeg-full.override { withUnfree = true; })
            brightnessctl
            eternal-terminal
          ]);

        services.redshift = lib.mkIf isDesktopMachine {
          enable = true;
          dawnTime = "7:00";
          duskTime = "16:35";
          temperature = {
            day = 6500;
            night = 3500;
          };
        };

        programs.delta = {
          enable = true;
          enableGitIntegration = true;
        };

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "*" = {
              ForwardAgent = false;
              HashKnownHosts = true;
              AddKeysToAgent = "yes";
            };
            "github.com" = {
              IdentityFile = "~/.ssh/identity/anderson";
            };
            "vondel-nord" = {
              User = "anderson";
              IdentityFile = "~/.ssh/access/vondel";
            };
          };
        };

        programs.obs-studio = lib.mkIf isDesktopMachine {
          enable = true;
          package = (
            pkgs.obs-studio.override {
              cudaSupport = true;
            }
          );
        };

        programs.lutris = lib.mkIf nixosConfig.custom.isGaming {
          enable = true;
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
          settings = {
            git.pagers = [
              {
                pager = "delta --dark --paging=never";
                colorArg = "always";
              }
            ];
          };
        };

        programs.lazydocker = {
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
            [[ -n "$HERDR_ENV" ]] && export PI_IMAGE_PROTOCOL=kitty
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

        # Global OpenCode config: personal AGENTS.md, agents, skills. The symlinks
        # point into this repo so edits apply without a switch; the thermo-nuclear
        # skill is a committed symlink inside home/opencode/skills/ to the samurai
        # checkout.
        home.file.".config/opencode/AGENTS.md" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/opencode/AGENTS.md";
        };

        home.file.".config/opencode/agents" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/opencode/agents";
        };

        home.file.".config/opencode/skills" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/configuration/home/opencode/skills";
        };

      };
  };
}
