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
          ./hex.nix
        ]);

        home.stateVersion = "25.05";

        home.username = "anderson";
        home.homeDirectory = "/home/anderson";

        home.packages =
          with pkgs;
          [
            neovim
            hunk
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

        # Entries link straight into the checkout so edits apply without a
        # rebuild. They are made here, not with home.file, because
        # mkOutOfStoreSymlink routes each link through two store paths that the
        # agent jails do not mount; a direct link only needs ~/configuration.
        # ln -T fails rather than nest a link inside a real directory.
        home.activation.checkoutLinks = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          let
            repo = "${config.home.homeDirectory}/configuration/home";
            skills = target: lib.mapAttrs' (name: _type: lib.nameValuePair "${target}/${name}" "skills/${name}") (
              builtins.readDir ./skills
            );
            links = {
              ".pi/agent/AGENTS.md" = "pi/AGENTS.md";
              ".claude/CLAUDE.md" = "claude/CLAUDE.md";
              ".ssh/config" = "ssh/config";
              ".config/nvim" = "nvim";
            }
            // skills ".pi/agent/skills"
            // skills ".claude/skills";
          in
          lib.concatStrings (
            lib.mapAttrsToList (dst: src: ''
              run mkdir -p "$(dirname "$HOME/${dst}")"
              run ln -sfnT "${repo}/${src}" "$HOME/${dst}"
            '') links
          )
        );

        home.file = lib.optionalAttrs (nixosConfig.custom.wallpaperFile != null) {
          "pictures/wallpaper".source = nixosConfig.custom.wallpaperFile;
        };

      };
  };
}
