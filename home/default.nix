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
        isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);
      in
      {
        imports = [
          ./herdr.nix
          ./url-open.nix
          ./sideshow.nix
          ./t3.nix
        ]
        ++ (lib.optionals isDesktopMachine [
          ./i3
          ./alacritty.nix
          ./ghostty.nix
        ]);

        home.stateVersion = "25.05";

        home.username = "anderson";
        home.homeDirectory = "/home/anderson";

        home.packages =
          with pkgs;
          [
            neovim
            hunk
            jailed-omp
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
          ])
          ++ (lib.optionals nixosConfig.custom.isGaming [
            (heroic.override {
              extraPkgs = pkgs': [ pkgs'.gamemode ];
            })
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

        # delta stays installed for the lazygit pager; git itself pages through hunk.
        programs.delta.enable = true;

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
              RemoteForward = "127.0.0.1:61413 127.0.0.1:61413";
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

        programs.git = {
          enable = true;
          settings = {
            core.pager = "hunk pager";
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

        # Agent instruction files and skills for omp, pi and claude,
        # linked directly instead of through the home-manager store
        # tree so edits in this checkout are picked up without a
        # rebuild. ~/.omp/agent also holds live state (sessions,
        # databases) — only the named entries below are managed;
        # config.yml backs up once before its first link. Foreign
        # entries in those directories stay.
        home.activation.agentLinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          OMP=${config.home.homeDirectory}/.omp/agent
          PI=${config.home.homeDirectory}/.pi/agent
          CLAUDE=${config.home.homeDirectory}/.claude
          $DRY_RUN_CMD mkdir -p $VERBOSE_ARG \
            $OMP/skills \
            $OMP/agents \
            $PI/skills \
            $CLAUDE/skills
          for name in AGENTS.md RULES.md config.yml keybindings.yml; do
            src=${config.home.homeDirectory}/configuration/home/omp/$name
            if [ -f "$OMP/$name" ] && [ ! -L "$OMP/$name" ]; then
              $DRY_RUN_CMD mv $VERBOSE_ARG "$OMP/$name" "$OMP/$name.backup"
            fi
            $DRY_RUN_CMD ln -sfn $VERBOSE_ARG "$src" "$OMP/$name"
          done
          for agent in ${config.home.homeDirectory}/configuration/home/omp/agents/*; do
            $DRY_RUN_CMD ln -sfn $VERBOSE_ARG "$agent" "$OMP/agents/$(basename "$agent")"
          done
          $DRY_RUN_CMD ln -sfn $VERBOSE_ARG \
            ${config.home.homeDirectory}/configuration/home/pi/AGENTS.md \
            $PI/AGENTS.md
          $DRY_RUN_CMD ln -sfn $VERBOSE_ARG \
            ${config.home.homeDirectory}/configuration/home/claude/CLAUDE.md \
            $CLAUDE/CLAUDE.md
          for skillsdir in $OMP/skills $PI/skills $CLAUDE/skills; do
            for skill in ${config.home.homeDirectory}/configuration/home/skills/*; do
              name=$(basename "$skill")
              if [ -d "$skillsdir/$name" ] && [ ! -L "$skillsdir/$name" ]; then
                $DRY_RUN_CMD rm -rf $VERBOSE_ARG "$skillsdir/$name"
              fi
              $DRY_RUN_CMD ln -sfn $VERBOSE_ARG "$skill" "$skillsdir/$name"
            done
          done
        '';

      };
  };
}
